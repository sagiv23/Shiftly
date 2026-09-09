import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
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
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(labelText: 'תעריף שעתי (חדש)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('תאריך תחילה', style: TextStyle(fontSize: 14)),
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
                  const Divider(height: 32),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'היסטוריית שכר:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...job.wageHistory!.reversed.take(3).map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(entry.startDate)),
                            Text(UIUtils.formatCurrency(entry.hourlyRate)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () async {
                final provider = context.read<ShiftProvider>();
                final name = nameController.text.trim();
                final rate = double.tryParse(rateController.text) ?? 0.0;

                final messenger = ScaffoldMessenger.of(context);

                if (name.isEmpty) {
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('נא להזין שם לתפקיד'),
                      duration: Duration(milliseconds: 4500),
                    ),
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
                    wageHistory: [WageEntry(startDate: effectiveDate, hourlyRate: rate)],
                  );
                  provider.addJobType(newJob);
                } else {
                  job.name = name;
                  job.hourlyRate = rate; // Update current rate
                  
                  // Add to history
                  job.wageHistory ??= [];
                  // Remove entry for same date if exists, then add
                  job.wageHistory!.removeWhere((e) => 
                    e.startDate.year == effectiveDate.year && 
                    e.startDate.month == effectiveDate.month && 
                    e.startDate.day == effectiveDate.day);
                  
                  job.wageHistory!.add(WageEntry(startDate: effectiveDate, hourlyRate: rate));
                  job.wageHistory!.sort((a, b) => a.startDate.compareTo(b.startDate));
                  
                  provider.updateJobType(job);
                }
                Navigator.pop(ctx);
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
        title: const Text(
          'הגדרות עבודה',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ), // Added bottom padding (100)
        children: [
          _buildSectionHeader('תזכורות משמרת'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('הפעל תזכורות'),
                    subtitle: const Text('שלח התראה לפני תחילת המשמרת'),
                    value: settings.shiftRemindersEnabled,
                    onChanged: (val) async {
                      await settings.setShiftRemindersEnabled(val);
                      if (!context.mounted) return;
                      context.read<ShiftProvider>().refreshAllReminders();
                    },
                  ),
                  if (settings.shiftRemindersEnabled) ...[
                    const Divider(height: 32),
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
                            color: Colors.blue,
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
          const SizedBox(height: 32),
          _buildSectionHeader('זמני הפסקות (דקות)'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _unpaidController,
                    decoration: const InputDecoration(
                      labelText: 'הפסקה ארוכה (ללא תשלום)',
                      prefixIcon: Icon(Icons.coffee_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
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

                      final messenger = ScaffoldMessenger.of(context);
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('זמני ההפסקות עודכנו'),
                          duration: Duration(milliseconds: 4500),
                        ),
                      );
                    },
                    child: const Text('עדכן זמנים'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSectionHeader('סוגי עבודות ותעריפים'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showEditJobDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('הוסף'),
              ),
            ],
          ),
          if (jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('לא נמצאו תפקידים.')),
            )
          else
            ...jobs.map((job) => _buildJobItem(context, job)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildJobItem(BuildContext context, JobType job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        child: ListTile(
          title: Text(
            job.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${UIUtils.formatCurrency(job.hourlyRate)} לשעה"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                onPressed: () => _showEditJobDialog(context, job),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () async {
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

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('תפקיד "$name" נמחק'),
                      duration: const Duration(milliseconds: 4500),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'ביטול',
                        onPressed: () {
                          provider.addJobType(job);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
