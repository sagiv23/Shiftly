import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/models/wage_entry.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/services/notification_service.dart';
import 'package:shiftly/theme/app_theme.dart';
import 'package:shiftly/utils/ui_utils.dart';
import 'package:uuid/uuid.dart';

class WorkConfigScreen extends StatefulWidget {
  const WorkConfigScreen({super.key});

  @override
  State<WorkConfigScreen> createState() => _WorkConfigScreenState();
}

class _WorkConfigScreenState extends State<WorkConfigScreen> {
  late TextEditingController _paidController;
  late TextEditingController _unpaidController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _paidController = TextEditingController(
      text: settings.paidBreakDurationMinutes.toStringAsFixed(0),
    );
    _unpaidController = TextEditingController(
      text: settings.unpaidBreakDurationMinutes.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _paidController.dispose();
    _unpaidController.dispose();
    super.dispose();
  }

  void _showEditJobDialog(BuildContext context, [JobType? job]) {
    final nameController = TextEditingController(text: job?.name ?? '');
    final rateController = TextEditingController(
      text: (job?.hourlyRate ?? 40.22).toString(),
    );
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(job == null ? 'הוספת סוג עבודה' : 'עריכת סוג עבודה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'שם התפקיד'),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'תעריף שעתי (חדש)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'תאריך תחילה',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(effectiveDate)),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: effectiveDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => effectiveDate = picked);
                    }
                  },
                ),
                if (job != null &&
                    job.wageHistory != null &&
                    job.wageHistory!.isNotEmpty) ...[
                  const Divider(height: AppTheme.spaceLg),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'היסטוריית שכר',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  _WageTimeline(
                    entries: job.wageHistory!,
                    compact: true,
                    maxItems: 4,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = context.read<ShiftProvider>();
                final name = nameController.text.trim();
                final rate = double.tryParse(rateController.text) ?? 0.0;

                if (name.isEmpty) {
                  UIUtils.showSnackBar(
                    context,
                    'נא להזין שם לתפקיד',
                    isError: true,
                  );
                  return;
                }

                final exists = provider.jobTypes.any(
                  (j) =>
                      j.name.toLowerCase() == name.toLowerCase() &&
                      j.id != job?.id,
                );

                if (exists) {
                  UIUtils.showSnackBar(
                    context,
                    'תפקיד בשם זה כבר קיים',
                    isError: true,
                  );
                  return;
                }

                if (rate < 0) {
                  UIUtils.showSnackBar(
                    context,
                    'השכר לא יכול להיות שלילי',
                    isError: true,
                  );
                  return;
                }

                final confirmed = await UIUtils.showConfirmDialog(
                  context: context,
                  title: job == null ? 'הוספת תפקיד' : 'עדכון תפקיד',
                  content:
                      'האם לשמור את התפקיד "$name" עם שכר של ${UIUtils.formatCurrency(rate)} החל מיום ${DateFormat('dd/MM/yyyy').format(effectiveDate)}?',
                );

                if (confirmed != true) return;
                if (!context.mounted) return;

                if (job == null) {
                  final newJob = JobType(
                    id: const Uuid().v4(),
                    name: name,
                    hourlyRate: rate,
                    wageHistory: [
                      WageEntry(startDate: effectiveDate, hourlyRate: rate),
                    ],
                  );
                  newJob.syncCurrentRate();
                  provider.addJobType(newJob);
                } else {
                  job.name = name;
                  job.wageHistory ??= [];
                  job.wageHistory!.removeWhere(
                    (e) =>
                        e.startDate.year == effectiveDate.year &&
                        e.startDate.month == effectiveDate.month &&
                        e.startDate.day == effectiveDate.day,
                  );
                  job.wageHistory!.add(
                    WageEntry(startDate: effectiveDate, hourlyRate: rate),
                  );
                  job.wageHistory!.sort(
                    (a, b) => a.startDate.compareTo(b.startDate),
                  );
                  job.syncCurrentRate();
                  await provider.updateJobType(job);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawJobs = context.watch<ShiftProvider>().jobTypes;
    final settings = context.watch<SettingsProvider>();

    final jobs = List<JobType>.from(rawJobs)
      ..sort((a, b) {
        if (a.name.contains('מזנון')) return -1;
        if (b.name.contains('מזנון')) return 1;
        if (a.name.contains('סדרן')) return -1;
        if (b.name.contains('סדרן')) return 1;
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות עבודה'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceSm,
          AppTheme.spaceSm,
          AppTheme.spaceSm,
          100,
        ),
        children: [
          _SectionLabel('תזכורות משמרת'),
          const SizedBox(height: AppTheme.spaceXs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('הפעל תזכורות'),
                    subtitle: const Text('שלח התראה לפני תחילת המשמרת'),
                    value: settings.shiftRemindersEnabled,
                    onChanged: (val) async {
                      await settings.setShiftRemindersEnabled(val);
                      if (val) {
                        await NotificationService.requestPermissions();
                      }
                      if (!context.mounted) return;
                      context.read<ShiftProvider>().refreshAllReminders();
                    },
                  ),
                  if (settings.shiftRemindersEnabled) ...[
                    const Divider(height: AppTheme.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'זמן תזכורת (שעות)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${settings.shiftReminderDurationHours % 1 == 0 ? settings.shiftReminderDurationHours.toInt() : settings.shiftReminderDurationHours} שעות',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.shiftReminderDurationHours,
                      min: 0.5,
                      max: 24,
                      divisions: 47,
                      onChanged: (val) async {
                        await settings.setShiftReminderDurationHours(val);
                        if (!context.mounted) return;
                        context.read<ShiftProvider>().refreshAllReminders();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _SectionLabel('זמני הפסקות (דקות)'),
          const SizedBox(height: AppTheme.spaceXs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: Column(
                children: [
                  TextField(
                    controller: _paidController,
                    decoration: const InputDecoration(
                      labelText: 'הפסקה קצרה (בתשלום)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextField(
                    controller: _unpaidController,
                    decoration: const InputDecoration(
                      labelText: 'הפסקה ארוכה (ללא תשלום)',
                      prefixIcon: Icon(Icons.coffee_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final paid =
                            double.tryParse(_paidController.text) ?? 20.0;
                        final unpaid =
                            double.tryParse(_unpaidController.text) ?? 45.0;

                        final confirmed = await UIUtils.showConfirmDialog(
                          context: context,
                          title: 'עדכון זמני הפסקה',
                          content:
                              'האם לעדכן את זמני ברירת המחדל ל-$paid דק\' בתשלום ו-$unpaid דק\' ללא תשלום?',
                        );

                        if (confirmed != true) return;
                        if (!context.mounted) return;

                        settings.setBreakDurations(paid, unpaid);

                        UIUtils.showSnackBar(context, 'זמני ההפסקות עודכנו');
                      },
                      child: const Text('עדכן זמנים'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              const Expanded(child: _SectionLabel('סוגי עבודות ותעריפים')),
              TextButton.icon(
                onPressed: () => _showEditJobDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('הוסף'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Center(
                child: Text(
                  'לא נמצאו תפקידים.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            ...jobs.map((job) => _JobCard(
                  job: job,
                  onEdit: () => _showEditJobDialog(context, job),
                  onDelete: () => _deleteJob(context, job),
                )),
        ],
      ),
    );
  }

  Future<void> _deleteJob(BuildContext context, JobType job) async {
    final provider = context.read<ShiftProvider>();
    final name = job.name;

    final confirmed = await UIUtils.showConfirmDialog(
      context: context,
      title: 'מחיקת תפקיד',
      content: 'האם אתה בטוח שברצונך למחוק את התפקיד "$name"?',
      isDestructive: true,
      confirmLabel: 'מחק',
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    provider.deleteJobType(job.id);

    UIUtils.showSnackBar(
      context,
      'תפקיד "$name" נמחק',
      action: SnackBarAction(
        label: 'ביטול',
        onPressed: () {
          provider.addJobType(job);
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobType job;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JobCard({
    required this.job,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentRate = job.getRateForDate(DateTime.now());
    final history = List<WageEntry>.from(job.wageHistory ?? const [])
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppTheme.iconForJobName(job.name),
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${UIUtils.formatCurrency(currentRate)} לשעה',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'עריכה',
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primaryDark,
                    ),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'מחיקה',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.expense,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSm),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  'היסטוריית שכר',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                _WageTimeline(entries: history),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual timeline showing wage raises over time (newest first).
class _WageTimeline extends StatelessWidget {
  final List<WageEntry> entries;
  final bool compact;
  final int? maxItems;

  const _WageTimeline({
    required this.entries,
    this.compact = false,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<WageEntry>.from(entries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final items = maxItems != null ? sorted.take(maxItems!).toList() : sorted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(items.length, (index) {
        final entry = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

        // Raise delta vs previous (older) entry in chronological sense
        double? delta;
        if (index < items.length - 1) {
          delta = entry.hourlyRate - items[index + 1].hourlyRate;
        } else if (sorted.length > items.length) {
          // truncated — skip
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: isFirst ? 12 : 10,
                      height: isFirst ? 12 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.45),
                        border: Border.all(
                          color: Theme.of(context).cardTheme.color ??
                              (isDark ? AppTheme.darkCard : Colors.white),
                          width: 2,
                        ),
                        boxShadow: isFirst
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: AppTheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : (compact ? 10 : 14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(entry.startDate),
                              style: TextStyle(
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            if (isFirst && !compact)
                              Text(
                                'תעריף נוכחי',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        UIUtils.formatCurrency(entry.hourlyRate),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 13 : 15,
                          color: isFirst
                              ? AppTheme.primaryDark
                              : Theme.of(context).colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (delta != null && delta != 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (delta > 0 ? AppTheme.profit : AppTheme.expense)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: delta > 0
                                  ? AppTheme.profitSoft
                                  : AppTheme.expenseSoft,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
