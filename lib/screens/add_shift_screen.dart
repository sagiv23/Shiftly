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
  const AddShiftScreen({super.key});

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual Form State
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  String? _selectedJobTypeId;
  final TextEditingController _tipsController = TextEditingController(
    text: '0',
  );
  BreakType _selectedBreakType = BreakType.none;

  // Raw Paste State
  final TextEditingController _rawTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final jobs = context.read<ShiftProvider>().jobTypes;
    if (jobs.isNotEmpty) {
      _selectedJobTypeId = jobs.first.id;
    }
  }

  double _getBreakDeduction(BreakType type) {
    switch (type) {
      case BreakType.none:
      case BreakType.twentyMinPaid:
        return 0.0;
      case BreakType.fortyFiveMinUnpaid:
        return 45.0;
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

    final shift = Shift(
      id: const Uuid().v4(),
      date: _selectedDate,
      startTime: start,
      endTime: end,
      jobTypeId: _selectedJobTypeId!,
      tips: double.tryParse(_tipsController.text) ?? 0,
      breakMinutes: _getBreakDeduction(_selectedBreakType),
      breakType: _selectedBreakType,
    );

    context.read<ShiftProvider>().addShift(shift);
    Navigator.pop(context);
  }

  void _saveRaw() {
    if (_selectedJobTypeId == null) return;

    final lines = _rawTextController.text.split('\n');
    int addedCount = 0;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // Note: Raw parser currently defaults to 'none' break type
      // since we don't have a format for break in text yet.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Shift'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'Raw Paste'),
          ],
        ),
      ),
      body: TabBarView(
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
            title: const Text('Date'),
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
            title: const Text('Start Time'),
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
            title: const Text('End Time'),
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
              'Break Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SegmentedButton<BreakType>(
            segments: const [
              ButtonSegment(value: BreakType.none, label: Text('None')),
              ButtonSegment(
                value: BreakType.twentyMinPaid,
                label: Text('20m (Paid)'),
              ),
              ButtonSegment(
                value: BreakType.fortyFiveMinUnpaid,
                label: Text('45m (Unpaid)'),
              ),
            ],
            selected: {_selectedBreakType},
            onSelectionChanged: (val) =>
                setState(() => _selectedBreakType = val.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedJobTypeId,
            decoration: const InputDecoration(labelText: 'Job Type'),
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
              labelText: 'Tips (₪)',
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
            child: const Text('Save Shift'),
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
              labelText: 'Default Job Type for Paste',
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
            'Format: DD.MM[.YYYY] - HH:mm - HH:mm [+ tips]\nExample: 24.6.2026 - 17:30 - 23:00 + 50',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _rawTextController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Paste shifts here...',
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
            child: const Text('Parse & Save'),
          ),
        ],
      ),
    );
  }
}
