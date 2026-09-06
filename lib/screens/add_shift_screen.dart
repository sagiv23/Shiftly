import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/break_type.dart';
import '../models/job_type.dart';
import '../models/shift.dart';
import '../providers/settings_provider.dart';
import '../providers/shift_provider.dart';
import '../services/shift_parser.dart';

class AddShiftScreen extends StatefulWidget {
  final Shift? shiftToEdit;

  const AddShiftScreen({super.key, this.shiftToEdit});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.shiftToEdit == null ? 2 : 1,
      vsync: this,
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
      final settings = context.read<SettingsProvider>();

      if (jobs.isNotEmpty) {
        // Find 'מזנון' as default
        final miznon = jobs.firstWhere(
          (j) => j.name.contains('מזנון'),
          orElse: () => jobs.first,
        );
        _selectedJobTypeId = miznon.id;
      }
    }
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
    final settings = context.watch<SettingsProvider>();

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
                  Tab(text: 'ידני'),
                  Tab(text: 'הדבקה חופשית'),
                ],
              ),
      ),
      body: isEditing
          ? _buildManualForm(jobs)
          : TabBarView(
              controller: _tabController,
              children: [_buildManualForm(jobs), _buildRawForm(jobs)],
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
