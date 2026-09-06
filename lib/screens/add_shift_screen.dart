import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/break_type.dart';
import '../models/job_type.dart';
import '../models/shift.dart';
import '../providers/settings_provider.dart';
import '../providers/shift_provider.dart';
import '../providers/timer_provider.dart';
import '../services/shift_parser.dart';

class AddShiftScreen extends StatefulWidget {
  final Shift? shiftToEdit;
  final int initialTabIndex;

  const AddShiftScreen({super.key, this.shiftToEdit, this.initialTabIndex = 0});

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual Form State
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedJobTypeId;
  late TextEditingController _tipsController;
  late BreakType _selectedBreakType;

  // Raw Paste State
  final TextEditingController _rawTextController = TextEditingController();

  // Timer State
  final TextEditingController _timerTipsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.shiftToEdit == null ? 3 : 1,
      vsync: this,
      initialIndex: widget.shiftToEdit == null ? widget.initialTabIndex : 0,
    );

    if (widget.shiftToEdit != null) {
      final s = widget.shiftToEdit!;
      _selectedDate = s.date;
      _startTime = TimeOfDay.fromDateTime(s.startTime);
      _endTime = TimeOfDay.fromDateTime(s.endTime);
      _selectedJobTypeId = s.jobTypeId;
      _tipsController = TextEditingController(text: s.tips.toString());
      _selectedBreakType = s.breakType ?? BreakType.none;
    } else {
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _tipsController = TextEditingController(text: '0');
      _selectedBreakType = BreakType.none;

      final jobs = context.read<ShiftProvider>().jobTypes;
      if (jobs.isNotEmpty) {
        final miznon = jobs.firstWhere(
          (j) => j.name.contains('מזנון'),
          orElse: () => jobs.first,
        );
        _selectedJobTypeId = miznon.id;
      }

      // Initialize timer tab values if timer is running
      final timerProvider = context.read<TimerProvider>();
      if (timerProvider.isRunning) {
        _selectedJobTypeId = timerProvider.jobTypeId ?? _selectedJobTypeId;
        _timerTipsController.text = timerProvider.tips.toStringAsFixed(0);
      }
    }
  }

  void _finishTimerShift() {
    final timerProvider = context.read<TimerProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    if (timerProvider.startTime == null || timerProvider.jobTypeId == null)
      return;

    final now = DateTime.now();
    final shift = Shift(
      id: const Uuid().v4(),
      date: timerProvider.startTime!,
      startTime: timerProvider.startTime!,
      endTime: now,
      jobTypeId: timerProvider.jobTypeId!,
      tips: timerProvider.tips,
      breakType: timerProvider.accumulatedBreakMinutes > 0
          ? BreakType.unpaid
          : BreakType.none,
      unpaidBreakMinutes: timerProvider.accumulatedBreakMinutes,
    );

    shiftProvider.addShift(shift);
    timerProvider.resetTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('המשמרת נשמרה בהצלחה'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _saveManual() {
    if (_selectedJobTypeId == null) return;

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    var end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final settings = context.read<SettingsProvider>();

    if (widget.shiftToEdit != null) {
      final s = widget.shiftToEdit!;
      s.date = _selectedDate;
      s.startTime = start;
      s.endTime = end;
      s.jobTypeId = _selectedJobTypeId!;
      s.tips = double.tryParse(_tipsController.text) ?? 0;
      s.breakType = _selectedBreakType;
      s.unpaidBreakMinutes = settings.unpaidBreakDurationMinutes;
      context.read<ShiftProvider>().updateShift(s);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('משמרת מיום $dateStr עודכנה בהצלחה'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final shift = Shift(
        id: const Uuid().v4(),
        date: _selectedDate,
        startTime: start,
        endTime: end,
        jobTypeId: _selectedJobTypeId!,
        tips: double.tryParse(_tipsController.text) ?? 0,
        breakType: _selectedBreakType,
        unpaidBreakMinutes: settings.unpaidBreakDurationMinutes,
      );
      context.read<ShiftProvider>().addShift(shift);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('משמרת מיום $dateStr נשמרה בהצלחה'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context);
  }

  void _saveRaw() {
    if (_selectedJobTypeId == null) return;
    final settings = context.read<SettingsProvider>();

    final lines = _rawTextController.text.split('\n');
    int addedCount = 0;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      final shift = ShiftParser.parse(
        line,
        _selectedJobTypeId!,
        paidMinutes: settings.paidBreakDurationMinutes,
        unpaidMinutes: settings.unpaidBreakDurationMinutes,
      );
      if (shift != null) {
        context.read<ShiftProvider>().addShift(shift);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse any shifts. Check format.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawJobs = context.watch<ShiftProvider>().jobTypes;

    // Sort jobs so 'מזנון' is always above 'סדרן'
    final jobs = List<JobType>.from(rawJobs)
      ..sort((a, b) {
        if (a.name.contains('מזנון')) return -1;
        if (b.name.contains('מזנון')) return 1;
        if (a.name.contains('סדרן')) return -1;
        if (b.name.contains('סדרן')) return 1;
        return a.name.compareTo(b.name);
      });

    final isEditing = widget.shiftToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'עריכת משמרת' : 'רישום משמרת'),
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'טיימר', icon: Icon(Icons.timer_outlined)),
                  Tab(text: 'ידני', icon: Icon(Icons.edit_note_rounded)),
                  Tab(text: 'הדבקה חופשית', icon: Icon(Icons.paste_rounded)),
                ],
              ),
      ),
      body: isEditing
          ? _buildManualForm(jobs)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimerForm(jobs),
                _buildManualForm(jobs),
                _buildRawForm(jobs),
              ],
            ),
    );
  }

  Widget _buildTimerForm(List<JobType> jobs) {
    final timerProvider = context.watch<TimerProvider>();
    final shiftProvider = context.watch<ShiftProvider>();
    final isRunning = timerProvider.isRunning;
    final isOnBreak = timerProvider.isOnBreak;
    final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = d.inHours;
      final minutes = twoDigits(d.inMinutes.remainder(60));
      final seconds = twoDigits(d.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Big Circle Button
          GestureDetector(
            onTap: () {
              if (!isRunning) {
                if (_selectedJobTypeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('בחר סוג עבודה קודם')),
                  );
                  return;
                }
                timerProvider.startShift(_selectedJobTypeId!);
                _timerTipsController.text = '0';
              } else {
                if (isOnBreak) {
                  timerProvider.toggleBreak();
                } else {
                  _showFinishDialog();
                }
              }
            },
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning
                    ? (isOnBreak
                          ? Colors.orange.shade400
                          : Theme.of(context).colorScheme.primary)
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isRunning
                                ? (isOnBreak
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.primary)
                                : Colors.grey)
                            .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 8,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRunning
                          ? (isOnBreak
                                ? Icons.play_arrow_rounded
                                : Icons.stop_rounded)
                          : Icons.play_arrow_rounded,
                      size: 64,
                      color: isRunning
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRunning
                          ? (isOnBreak ? 'חזור לעבודה' : 'סיים משמרת')
                          : 'התחל משמרת',
                      style: TextStyle(
                        color: isRunning
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Timer Display
          Text(
            formatDuration(timerProvider.elapsed),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          // Live Pay Display
          Text(
            '₪${timerProvider.calculateLivePay(job?.hourlyRate ?? 40.22).toStringAsFixed(2)} נצבר',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (isOnBreak || timerProvider.accumulatedBreakMinutes > 0)
            Column(
              children: [
                Text(
                  isOnBreak
                      ? 'בהפסקה ללא תשלום: ${formatDuration(timerProvider.currentBreakElapsed)}'
                      : 'סה"כ הפסקה (לא בתשלום): ${timerProvider.accumulatedBreakMinutes.toStringAsFixed(1)} דק\'',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'הפסקה בטיימר מנוכה מזמן העבודה הכולל',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          const SizedBox(height: 40),

          // Controls Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: isRunning
                        ? timerProvider.jobTypeId
                        : _selectedJobTypeId,
                    decoration: const InputDecoration(
                      labelText: 'סוג עבודה',
                      prefixIcon: Icon(Icons.work_rounded),
                    ),
                    items: jobs
                        .map(
                          (j) => DropdownMenuItem(
                            value: j.id,
                            child: Text(j.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      if (isRunning) {
                        timerProvider.setJobType(val);
                      } else {
                        setState(() => _selectedJobTypeId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timerTipsController,
                    decoration: const InputDecoration(
                      labelText: 'טיפים (₪)',
                      prefixIcon: Icon(Icons.monetization_on_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final d = double.tryParse(val) ?? 0.0;
                      if (isRunning) {
                        timerProvider.setTips(d);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Break/Finish Buttons
          if (isRunning)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => timerProvider.toggleBreak(),
                    icon: Icon(
                      isOnBreak
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(isOnBreak ? 'סיים הפסקה' : 'צא להפסקה'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade700),
                      foregroundColor: Colors.orange.shade700,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showFinishDialog,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('סיום'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isRunning)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('איפוס טיימר'),
                    content: const Text(
                      'האם אתה בטוח שברצונך לאפס את הטיימר? כל המידע הנוכחי יימחק.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('ביטול'),
                      ),
                      TextButton(
                        onPressed: () {
                          timerProvider.resetTimer();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'אפס',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'ביטול ואיפוס',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('סיום משמרת'),
        content: const Text(
          'האם אתה בטוח שברצונך לסיים את המשמרת ולשמור אותה?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishTimerShift();
            },
            child: const Text('סיים ושמור'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm(List<JobType> jobs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'תאריך',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'שעת התחלה',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_startTime.format(context)),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'שעת סיום',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_endTime.format(context)),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Text(
              'סוג הפסקה',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<BreakType>(
              segments: [
                const ButtonSegment(value: BreakType.none, label: Text('ללא')),
                ButtonSegment(
                  value: BreakType.paid,
                  label: Text(
                    '${context.read<SettingsProvider>().paidBreakDurationMinutes.toStringAsFixed(0)} דק\' (בתשלום)',
                  ),
                ),
                ButtonSegment(
                  value: BreakType.unpaid,
                  label: Text(
                    '${context.read<SettingsProvider>().unpaidBreakDurationMinutes.toStringAsFixed(0)} דק\' (לא בתשלום)',
                  ),
                ),
              ],
              selected: {_selectedBreakType},
              onSelectionChanged: (val) =>
                  setState(() => _selectedBreakType = val.first),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedJobTypeId,
            decoration: const InputDecoration(
              labelText: 'סוג עבודה',
              prefixIcon: Icon(Icons.work_rounded),
            ),
            items: jobs
                .map(
                  (j) => DropdownMenuItem<String>(
                    value: j.id,
                    child: Text(j.name),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedJobTypeId = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tipsController,
            decoration: InputDecoration(
              labelText: 'טיפים (₪)',
              prefixIcon: const Icon(Icons.monetization_on_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.backspace_rounded, size: 20),
                onPressed: () => _tipsController.text = '0',
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _saveManual,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              widget.shiftToEdit != null ? 'עדכן משמרת' : 'שמור משמרת',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawForm(List<JobType> jobs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedJobTypeId,
            decoration: const InputDecoration(
              labelText: 'סוג עבודה ברירת מחדל להדבקה',
              prefixIcon: Icon(Icons.work_history_rounded),
            ),
            items: jobs
                .map(
                  (j) => DropdownMenuItem<String>(
                    value: j.id,
                    child: Text(j.name),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedJobTypeId = val),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'פורמט: DD.MM[.YYYY] - HH:mm - HH:mm [הפסקה] [+ tips]\n'
                    'הפסקות: ללא / 20 דקות / 45 דקות',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: TextField(
                controller: _rawTextController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText:
                      'הדבק משמרות כאן...\nלדוגמה:\n24.6.2026 - 17:30 - 23:00 45 דקות + 50',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saveRaw,
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('פענח ושמור הכל'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
