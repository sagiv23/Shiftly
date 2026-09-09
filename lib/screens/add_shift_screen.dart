import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/models/break_type.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/models/shift.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/providers/timer_provider.dart';
import 'package:shiftly/services/shift_parser.dart';
import 'package:shiftly/utils/ui_utils.dart';
import 'package:uuid/uuid.dart';

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
  final List<TextEditingController> _tipControllers = [];
  late BreakType _selectedBreakType;

  // Raw Paste State
  final TextEditingController _rawTextController = TextEditingController();

  // Timer State
  final List<TextEditingController> _timerTipControllers = [];

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
      _selectedBreakType = s.breakType ?? BreakType.none;

      // Initialize tips for editing
      if (s.tips > 0) {
        _tipControllers.add(
          TextEditingController(text: s.tips.toStringAsFixed(0)),
        );
      } else {
        _tipControllers.add(TextEditingController(text: '0'));
      }
    } else {
      _tipControllers.add(TextEditingController(text: '0'));
      _timerTipControllers.add(TextEditingController(text: '0'));

      final timer = context.read<TimerProvider>();
      final isFromTimerReview = timer.startTime != null && !timer.isRunning;

      if (isFromTimerReview) {
        _selectedDate = timer.startTime!;
        _startTime = TimeOfDay.fromDateTime(timer.startTime!);
        _endTime = TimeOfDay.fromDateTime(
          timer.reviewEndTime ?? DateTime.now(),
        );
        _selectedJobTypeId = timer.jobTypeId;
        _selectedBreakType = timer.accumulatedUnpaidMinutes > 0
            ? BreakType.unpaid
            : BreakType.none;

        _tipControllers.clear();
        _tipControllers.add(
          TextEditingController(text: timer.tips.toStringAsFixed(0)),
        );
        _timerTipControllers.clear();
        _timerTipControllers.add(
          TextEditingController(text: timer.tips.toStringAsFixed(0)),
        );
      } else {
        _selectedDate = DateTime.now();
        _startTime = const TimeOfDay(hour: 9, minute: 0);
        _endTime = const TimeOfDay(hour: 17, minute: 0);
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
        if (timer.isRunning) {
          _selectedJobTypeId = timer.jobTypeId ?? _selectedJobTypeId;
          _timerTipControllers.clear();
          _timerTipControllers.add(
            TextEditingController(text: timer.tips.toStringAsFixed(0)),
          );
        }
      }
    }
  }

  double _calculateTotalTips(List<TextEditingController> controllers) {
    return controllers.fold(
      0.0,
      (sum, c) => sum + (double.tryParse(c.text) ?? 0.0),
    );
  }

  List<double> _getTipList(List<TextEditingController> controllers) {
    return controllers
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .where((t) => t > 0)
        .toList();
  }

  void _finishTimerShift() async {
    final timerProvider = context.read<TimerProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    if (timerProvider.startTime == null || timerProvider.jobTypeId == null) {
      return;
    }

    final totalTips = _calculateTotalTips(_timerTipControllers);
    final confirmed = await UIUtils.showConfirmDialog(
      context: context,
      title: 'סיום משמרת',
      content:
          'האם אתה בטוח שברצונך לשמור את המשמרת עם טיפים בסך ${UIUtils.formatCurrency(totalTips)}?',
    );
    if (!confirmed) return;

    final end = timerProvider.isRunning
        ? DateTime.now()
        : (timerProvider.reviewEndTime ?? DateTime.now());

    final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");

    final shift = Shift(
      id: const Uuid().v4(),
      date: timerProvider.startTime!,
      startTime: timerProvider.startTime!,
      endTime: end,
      jobTypeId: timerProvider.jobTypeId!,
      tips: totalTips,
      individualTips: _getTipList(_timerTipControllers),
      hourlyRate: job?.getRateForDate(timerProvider.startTime!),
      breakType: timerProvider.accumulatedUnpaidMinutes > 0
          ? BreakType.unpaid
          : BreakType.none,
      unpaidBreakMinutes: timerProvider.accumulatedUnpaidMinutes,
    );

    shiftProvider.addShift(shift);
    timerProvider.resetTimer();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('המשמרת נשמרה בהצלחה'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 4500),
      ),
    );
    Navigator.pop(context);
  }

  void _saveManual() async {
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
    final totalTips = _calculateTotalTips(_tipControllers);
    final shiftProvider = context.read<ShiftProvider>();

    final confirmed = await UIUtils.showConfirmDialog(
      context: context,
      title: widget.shiftToEdit != null ? 'עדכון משמרת' : 'שמירת משמרת',
      content:
          'האם לשמור את פרטי המשמרת מיום $dateStr עם טיפים בסך ${UIUtils.formatCurrency(totalTips)}?',
    );
    if (confirmed != true) return;

    if (!context.mounted) return;

    final job = shiftProvider.getJobTypeById(_selectedJobTypeId!);

    if (widget.shiftToEdit != null) {
      final s = widget.shiftToEdit!;
      s.date = _selectedDate;
      s.startTime = start;
      s.endTime = end;
      s.jobTypeId = _selectedJobTypeId!;
      s.tips = totalTips;
      s.individualTips = _getTipList(_tipControllers);
      s.hourlyRate = job?.getRateForDate(_selectedDate);
      s.breakType = _selectedBreakType;
      s.unpaidBreakMinutes = settings.unpaidBreakDurationMinutes;
      if (!context.mounted) return;
      shiftProvider.updateShift(s);

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('משמרת מיום $dateStr עודכנה בהצלחה'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 4500),
        ),
      );
    } else {
      final shift = Shift(
        id: const Uuid().v4(),
        date: _selectedDate,
        startTime: start,
        endTime: end,
        jobTypeId: _selectedJobTypeId!,
        tips: totalTips,
        individualTips: _getTipList(_tipControllers),
        hourlyRate: job?.getRateForDate(_selectedDate),
        breakType: _selectedBreakType,
        unpaidBreakMinutes: settings.unpaidBreakDurationMinutes,
      );
      if (!context.mounted) return;
      shiftProvider.addShift(shift);

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('משמרת מיום $dateStr נשמרה בהצלחה'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 4500),
        ),
      );
    }
    if (context.mounted) Navigator.pop(context);
  }

  void _saveRaw() async {
    if (_selectedJobTypeId == null) return;
    final settings = context.read<SettingsProvider>();

    final lines = _rawTextController.text.split('\n');
    final validLines = lines.where((l) => l.trim().isNotEmpty).toList();
    if (validLines.isEmpty) return;

    final confirmed = await UIUtils.showConfirmDialog(
      context: context,
      title: 'פענוח משמרות',
      content: 'האם לפענח ולשמור ${validLines.length} משמרות מהטקסט שהודבק?',
    );
    if (!confirmed) return;

    int addedCount = 0;
    for (var line in validLines) {
      final shift = ShiftParser.parse(
        line,
        _selectedJobTypeId!,
        paidMinutes: settings.paidBreakDurationMinutes,
        unpaidMinutes: settings.unpaidBreakDurationMinutes,
      );
      if (shift != null) {
        if (!context.mounted) continue;
        context.read<ShiftProvider>().addShift(shift);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      if (!context.mounted) return;
      Navigator.pop(context);
    } else {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('בדוק שוב האם הפורמט שהזנת תקין'),
          duration: Duration(milliseconds: 4500),
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
    final isReviewMode = timerProvider.startTime != null && !isRunning;
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
              if (isReviewMode) {
                timerProvider.resumeShift();
                _tabController.animateTo(0);
              } else if (!isRunning) {
                if (_selectedJobTypeId == null) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('בחר סוג עבודה קודם'),
                      duration: Duration(milliseconds: 4500),
                    ),
                  );
                  return;
                }
                timerProvider.startShift(_selectedJobTypeId!);
                for (var c in _timerTipControllers) {
                  c.text = '0';
                }
              } else {
                if (isOnBreak) {
                  timerProvider.endBreak();
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
                color: isReviewMode
                    ? Colors.green.shade500
                    : (isRunning
                          ? (isOnBreak
                                ? Colors.orange.shade400
                                : Theme.of(context).colorScheme.primary)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isReviewMode
                                ? Colors.green
                                : (isRunning
                                      ? (isOnBreak
                                            ? Colors.orange
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary)
                                      : Colors.grey))
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
                      isReviewMode
                          ? Icons.play_arrow_rounded
                          : (isRunning
                                ? (isOnBreak
                                      ? Icons.play_arrow_rounded
                                      : Icons.stop_rounded)
                                : Icons.play_arrow_rounded),
                      size: 64,
                      color: isReviewMode || isRunning
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReviewMode
                          ? 'המשך משמרת'
                          : (isRunning
                                ? (isOnBreak ? 'חזור לעבודה' : 'סיים משמרת')
                                : 'התחל משמרת'),
                      style: TextStyle(
                        color: isReviewMode || isRunning
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
            '${UIUtils.formatCurrency(timerProvider.calculateLivePay(job?.hourlyRate ?? 40.22))} נצבר',
            style: UIUtils.getCurrencyStyle(
              context,
              timerProvider.calculateLivePay(job?.hourlyRate ?? 40.22),
              positiveColor: Theme.of(context).colorScheme.primary,
              baseStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isOnBreak || timerProvider.accumulatedUnpaidMinutes > 0)
            Column(
              children: [
                if (isOnBreak)
                  Text(
                    'ספירה לאחור: ${timerProvider.breakRemaining.inMinutes}:${(timerProvider.breakRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: timerProvider.activeBreakType == BreakType.paid
                          ? Colors.blue
                          : Colors.orange.shade700,
                    ),
                  ),
                Text(
                  isOnBreak
                      ? (timerProvider.activeBreakType == BreakType.paid
                            ? 'בהפסקה בתשלום...'
                            : 'בהפסקה ללא תשלום (השעון עצר)')
                      : 'סה"כ הפסקה (לא בתשלום): ${timerProvider.accumulatedUnpaidMinutes.toStringAsFixed(1)} דק\'',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
                    initialValue: (isRunning || isReviewMode)
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
                      if (isRunning || isReviewMode) {
                        timerProvider.setJobType(val);
                      } else {
                        setState(() => _selectedJobTypeId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildTipsSection(_timerTipControllers),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Break/Finish Buttons
          if (isRunning || isReviewMode)
            Row(
              children: [
                if (!isReviewMode)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final settings = context.read<SettingsProvider>();
                        timerProvider.toggleBreak(
                          BreakType.paid,
                          settings.paidBreakDurationMinutes,
                        );
                      },
                      icon: Icon(
                        (isOnBreak &&
                                timerProvider.activeBreakType == BreakType.paid)
                            ? Icons.play_arrow_rounded
                            : Icons.timer_outlined,
                      ),
                      label: Text(
                        (isOnBreak &&
                                timerProvider.activeBreakType == BreakType.paid)
                            ? 'סיים הפסקה'
                            : 'הפסקה בתשלום',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        foregroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                if (!isReviewMode) const SizedBox(width: 8),
                if (!isReviewMode)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final settings = context.read<SettingsProvider>();
                        timerProvider.toggleBreak(
                          BreakType.unpaid,
                          settings.unpaidBreakDurationMinutes,
                        );
                      },
                      icon: Icon(
                        (isOnBreak &&
                                timerProvider.activeBreakType ==
                                    BreakType.unpaid)
                            ? Icons.play_arrow_rounded
                            : Icons.coffee_outlined,
                      ),
                      label: Text(
                        (isOnBreak &&
                                timerProvider.activeBreakType ==
                                    BreakType.unpaid)
                            ? 'סיים הפסקה'
                            : 'הפסקה ללא תשלום',
                      ),
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
              ],
            ),
          const SizedBox(height: 16),
          if (isRunning || isReviewMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isReviewMode ? _finishTimerShift : _showFinishDialog,
                icon: Icon(
                  isReviewMode ? Icons.check_rounded : Icons.stop_rounded,
                ),
                label: Text(isReviewMode ? 'שמור וסיים' : 'סיום משמרת'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReviewMode
                      ? Colors.green
                      : Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (isRunning || isReviewMode)
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
    // Stop the timer immediately when showing the dialog to allow review
    context.read<TimerProvider>().stopShift();

    showDialog(
      context: context,
      barrierDismissible: false, // Force choice
      builder: (ctx) => AlertDialog(
        title: const Text('סיום משמרת'),
        content: const Text(
          'הטיימר נעצר. האם ברצונך לשמור את המשמרת או להמשיך בעבודה?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimerProvider>().resumeShift();
            },
            child: const Text('המשך עבודה'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishTimerShift();
            },
            child: const Text('שמור וסיים'),
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
            initialValue: _selectedJobTypeId,
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
          const SizedBox(height: 24),
          _buildTipsSection(_tipControllers),
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
            initialValue: _selectedJobTypeId,
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
                ).colorScheme.onSecondaryContainer.withValues(alpha: 0.1),
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

  Widget _buildTipsSection(List<TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'טיפים (₪)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'סה"כ: ${UIUtils.formatCurrency(_calculateTotalTips(controllers))}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...controllers.asMap().entries.map((entry) {
          int idx = entry.key;
          var controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'הזן סכום טיפ',
                      prefixIcon: Icon(Icons.monetization_on_rounded, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => setState(() {
                      controllers.removeAt(idx);
                    }),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() {
            controllers.add(TextEditingController(text: '0'));
          }),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('הוסף טיפ נוסף'),
        ),
      ],
    );
  }
}
