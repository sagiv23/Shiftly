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
        title: const Text(
          'Shiftly',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline_rounded),
            tooltip: 'סוגי עבודות',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobTypesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'הגדרות',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupedShifts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'עדיין לא נרשמו משמרות.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: groupedShifts.length,
              itemBuilder: (context, index) {
                final monthKey = groupedShifts.keys.elementAt(index);
                final shifts = groupedShifts[monthKey]!;
                // Keep the latest month expanded by default
                return _MonthExpansionSection(
                  monthKey: monthKey,
                  shifts: shifts,
                  initiallyExpanded: index == 0,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('משמרת חדשה'),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'הוסף משמרת',
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AddShiftScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
          ),
        ),
      ),
    );
  }
}

class _MonthExpansionSection extends StatelessWidget {
  final String monthKey;
  final List<Shift> shifts;
  final bool initiallyExpanded;

  const _MonthExpansionSection({
    required this.monthKey,
    required this.shifts,
    required this.initiallyExpanded,
  });

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

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            "$monthName $year",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text(
            "₪${(totalBaseSalary + totalTips).toStringAsFixed(2)} סה\"כ | ${totalNetHours.toStringAsFixed(1)} שעות",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryItem(
                      label: 'שכר בסיס',
                      value: "₪${totalBaseSalary.toStringAsFixed(2)}",
                    ),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    _SummaryItem(
                      label: 'טיפים',
                      value: "₪${totalTips.toStringAsFixed(2)}",
                    ),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    _SummaryItem(
                      label: 'סה"כ',
                      value:
                          "₪${(totalBaseSalary + totalTips).toStringAsFixed(2)}",
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            ...shifts.map((shift) => _ShiftTile(shift: shift)),
            const SizedBox(height: 12),
          ],
        ),
      ),
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
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade700),
      ),
      onDismissed: (_) {
        final dateStr = DateFormat('dd/MM/yyyy').format(shift.date);
        shiftProvider.deleteShift(shift.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('משמרת מיום $dateStr נמחקה'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'ביטול',
              onPressed: () => shiftProvider.addShift(shift),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AddShiftScreen(shiftToEdit: shift),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      );
                    },
              ),
            );
          },
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                DateFormat.d().format(shift.date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          title: Text(
            "${job?.name ?? 'לא ידוע'}$breakInfo",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            "${DateFormat.Hm().format(shift.startTime)} - ${DateFormat.Hm().format(shift.endTime)} | "
            "${shift.netHours.toStringAsFixed(1)} ש'",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₪${pay.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (shift.tips > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "+₪${shift.tips.toStringAsFixed(2)} טיפ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
