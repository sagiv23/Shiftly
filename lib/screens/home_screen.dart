import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/break_type.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import 'add_shift_screen.dart';
import 'job_types_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final groupedShifts = shiftProvider.shiftsGroupedByMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip: 'סוגי עבודות',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobTypesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'הגדרות',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: groupedShifts.isEmpty
          ? const Center(child: Text('עדיין לא נרשמו משמרות.'))
          : ListView.builder(
              itemCount: groupedShifts.length,
              itemBuilder: (context, index) {
                final monthKey = groupedShifts.keys.elementAt(index);
                final shifts = groupedShifts[monthKey]!;
                return _MonthSection(monthKey: monthKey, shifts: shifts);
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'הוסף משמרת',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddShiftScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String monthKey;
  final List<Shift> shifts;

  const _MonthSection({required this.monthKey, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.read<ShiftProvider>();

    double totalNetHours = 0;
    double totalBaseSalary = 0;
    double totalTips = 0;

    for (var shift in shifts) {
      final job = shiftProvider.getJobTypeById(shift.jobTypeId);
      final rate = job?.hourlyRate ?? 40.22;
      totalNetHours += shift.netHours;
      totalBaseSalary += shift.netHours * rate;
      totalTips += shift.tips;
    }

    final date = DateTime.parse("$monthKey-01");
    final monthName = DateFormat.MMMM('he_IL').format(date);
    final year = date.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "$monthName $year",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SummaryItem(
                        label: 'שעות',
                        value: totalNetHours.toStringAsFixed(2),
                      ),
                      _SummaryItem(
                        label: 'שכר בסיס',
                        value: "₪${totalBaseSalary.toStringAsFixed(2)}",
                      ),
                      _SummaryItem(
                        label: 'טיפים',
                        value: "₪${totalTips.toStringAsFixed(2)}",
                      ),
                      _SummaryItem(
                        label: 'סה"כ',
                        value:
                            "₪${(totalBaseSalary + totalTips).toStringAsFixed(2)}",
                        isBold: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ...shifts.map((shift) => _ShiftTile(shift: shift)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final Shift shift;

  const _ShiftTile({required this.shift});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.read<ShiftProvider>();
    final job = shiftProvider.getJobTypeById(shift.jobTypeId);
    final rate = job?.hourlyRate ?? 40.22;
    final pay = shift.calculateTotalPay(rate);

    String breakInfo = "";
    if (shift.breakType == BreakType.twentyMinPaid) {
      breakInfo = " (20 דק' בתשלום)";
    } else if (shift.breakType == BreakType.fortyFiveMinUnpaid) {
      breakInfo = " (45 דק' ללא תשלום)";
    }

    return Dismissible(
      key: Key(shift.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        shiftProvider.deleteShift(shift.id);
      },
      child: ListTile(
        leading: CircleAvatar(child: Text(DateFormat.d().format(shift.date))),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddShiftScreen(shiftToEdit: shift),
            ),
          );
        },
        title: Text("${job?.name ?? 'לא ידוע'}$breakInfo"),
        subtitle: Text(
          "${DateFormat('dd/MM/yyyy').format(shift.date)} | "
          "${DateFormat.Hm().format(shift.startTime)} - ${DateFormat.Hm().format(shift.endTime)} "
          "(${shift.netHours.toStringAsFixed(2)} ש') | ₪${rate.toStringAsFixed(2)} לשעה",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₪${pay.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (shift.tips > 0)
              Text(
                "+₪${shift.tips.toStringAsFixed(0)} טיפ",
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
