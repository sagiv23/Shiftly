import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/job_type.dart';
import '../providers/settings_provider.dart';
import '../providers/shift_provider.dart';

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
      text: job?.hourlyRate.toString() ?? '40.22',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(job == null ? 'הוספת סוג עבודה' : 'עריכת סוג עבודה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'שם התפקיד'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: 'תעריף שעתי'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<ShiftProvider>();
              final name = nameController.text.trim();
              final rate = double.tryParse(rateController.text) ?? 0.0;

              final messenger = ScaffoldMessenger.of(context);

              if (name.isEmpty) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('נא להזין שם לתפקיד'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }

              // Check if name already exists (excluding the current job being edited)
              final exists = provider.jobTypes.any(
                (j) =>
                    j.name.toLowerCase() == name.toLowerCase() &&
                    j.id != job?.id,
              );

              if (exists) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('תפקיד בשם זה כבר קיים'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }

              if (rate < 0) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('השכר לא יכול להיות שלילי'),
                    duration: Duration(milliseconds: 4500),
                  ),
                );
                return;
              }

              if (job == null) {
                provider.addJobType(
                  JobType(id: const Uuid().v4(), name: name, hourlyRate: rate),
                );
              } else {
                job.name = name;
                job.hourlyRate = rate;
                provider.updateJobType(job);
              }
              Navigator.pop(ctx);
            },
            child: const Text('שמור'),
          ),
        ],
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
                    onPressed: () {
                      final paid =
                          double.tryParse(_paidController.text) ?? 20.0;
                      final unpaid =
                          double.tryParse(_unpaidController.text) ?? 45.0;
                      settings.setBreakDurations(paid, unpaid);

                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
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
          subtitle: Text("₪${job.hourlyRate.toStringAsFixed(2)} לשעה"),
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
                onPressed: () {
                  final provider = context.read<ShiftProvider>();
                  final name = job.name;
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
