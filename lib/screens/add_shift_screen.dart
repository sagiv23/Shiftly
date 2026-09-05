import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/break_type.dart';
import '../models/job_type.dart';
import '../models/shift.dart';
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
        length: widget.shiftToEdit == null ? 2 : 1, vsync: this);

    if (widget.shiftToEdit != null) {
      final s = widget.shiftToEdit!;
      _selectedDate = s.date;
      _startTime = TimeOfDay.fromDateTime(s.startTime);
      _endTime = TimeOfDay.fromDateTime(s.endTime);
      _selectedJobTypeId = s.jobTypeId;
      _tipsController = TextEditingController(text: s.tips.toString());
      _selectedBreakType = s.breakType;
    } else {
      _selectedDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _tipsController = TextEditingController(text: '0');
      _selectedBreakType = BreakType.none;
      final jobs = context.read<ShiftProvider>().jobTypes;
      if (jobs.isNotEmpty) {
        _selectedJobTypeId = jobs.first.id;
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

    if (widget.shiftToEdit != null) {
      final s = widget.shiftToEdit!;
      s.date = _selectedDate;
      s.startTime = start;
      s.endTime = end;
      s.jobTypeId = _selectedJobTypeId!;
      s.tips = double.tryParse(_tipsController.text) ?? 0;
      s.breakType = _selectedBreakType;
      context.read<ShiftProvider>().updateShift(s);
    } else {
      final shift = Shift(
        id: const Uuid().v4(),
        date: _selectedDate,
        startTime: start,
        endTime: end,
        jobTypeId: _selectedJobTypeId!,
        tips: double.tryParse(_tipsController.text) ?? 0,
        breakType: _selectedBreakType,
      );
      context.read<ShiftProvider>().addShift(shift);
    }
    Navigator.pop(context);
  }

  void _saveRaw() {
    if (_selectedJobTypeId == null) return;

    final lines = _rawTextController.text.split('\n');
    int addedCount = 0;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      final shift = ShiftParser.parse(line, _selectedJobTypeId!);
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
    final jobs = context.watch<ShiftProvider>().jobTypes;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('תאריך'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
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
          ListTile(
            title: const Text('שעת התחלה'),
            subtitle: Text(_startTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (picked != null) setState(() => _startTime = picked);
            },
          ),
          ListTile(
            title: const Text('שעת סיום'),
            subtitle: Text(_endTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (picked != null) setState(() => _endTime = picked);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'סוג הפסקה',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SegmentedButton<BreakType>(
            segments: const [
              ButtonSegment(value: BreakType.none, label: Text('ללא')),
              ButtonSegment(
                value: BreakType.twentyMinPaid,
                label: Text('20 דק\' (בתשלום)'),
              ),
              ButtonSegment(
                value: BreakType.fortyFiveMinUnpaid,
                label: Text('45 דק\' (לא בתשלום)'),
              ),
            ],
            selected: {_selectedBreakType},
            onSelectionChanged: (val) =>
                setState(() => _selectedBreakType = val.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedJobTypeId,
            decoration: const InputDecoration(labelText: 'סוג עבודה'),
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
          TextField(
            controller: _tipsController,
            decoration: InputDecoration(
              labelText: 'טיפים (₪)',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _tipsController.text = '0',
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveManual,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('שמור משמרת'),
          ),
        ],
      ),
    );
  }

  Widget _buildRawForm(List<JobType> jobs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedJobTypeId,
            decoration: const InputDecoration(
              labelText: 'סוג עבודה ברירת מחדל להדבקה',
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
          const Text(
            'פורמט: DD.MM[.YYYY] - HH:mm - HH:mm [הפסקה] [+ tips]\n'
            'הפסקות: ללא / 20 דקות / 45 דקות\n'
            'דוגמה: 24.6.2026 - 17:30 - 23:00 45 דקות + 50',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _rawTextController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'הדבק משמרות כאן...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveRaw,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('פענח ושמור'),
          ),
        ],
      ),
    );
  }
}
