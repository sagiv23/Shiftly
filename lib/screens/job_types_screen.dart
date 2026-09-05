import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/job_type.dart';
import '../providers/shift_provider.dart';

class JobTypesScreen extends StatelessWidget {
  const JobTypesScreen({super.key});

  void _showEditDialog(BuildContext context, [JobType? job]) {
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
              if (job == null) {
                provider.addJobType(
                  JobType(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    hourlyRate: double.tryParse(rateController.text) ?? 40.22,
                  ),
                );
              } else {
                job.name = nameController.text;
                job.hourlyRate = double.tryParse(rateController.text) ?? 40.22;
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
          'סוגי עבודות',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: jobs.isEmpty
          ? const Center(child: Text('לא נמצאו תפקידים.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      title: Text(
                        job.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "תעריף שעתי: ₪${job.hourlyRate.toStringAsFixed(2)}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showEditDialog(context, job),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () => context
                                .read<ShiftProvider>()
                                .deleteJobType(job.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context),
        label: const Text('הוסף תפקיד'),
        icon: const Icon(Icons.add_task_rounded),
      ),
    );
  }
}
