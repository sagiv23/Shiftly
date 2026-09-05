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
    final jobs = context.watch<ShiftProvider>().jobTypes;

    return Scaffold(
      appBar: AppBar(title: const Text('סוגי עבודות')),
      body: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return ListTile(
            title: Text(job.name),
            subtitle: Text("תעריף: ₪${job.hourlyRate.toStringAsFixed(2)}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, job),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      context.read<ShiftProvider>().deleteJobType(job.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
