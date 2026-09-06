import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/break_type.dart';
import '../models/shift.dart';
import '../providers/settings_provider.dart';
import '../providers/shift_provider.dart';
import '../providers/timer_provider.dart';
import 'add_shift_screen.dart';
import 'calendar_screen.dart';
import 'job_types_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final groupedShifts = shiftProvider.shiftsGroupedByMonth;

    // Calculate Grand Totals
    double grandTotalNetHours = 0;
    double grandTotalBaseSalary = 0;
    double grandTotalTips = 0;

    for (var shift in shiftProvider.shifts) {
      final job = shiftProvider.getJobTypeById(shift.jobTypeId);
      final rate = job?.hourlyRate ?? 40.22;
      grandTotalNetHours += shift.netHours;
      grandTotalBaseSalary += shift.netHours * rate;
      grandTotalTips += shift.tips;
    }

    // Include Active or Paused Timer in Grand Total
    if (timerProvider.startTime != null) {
      final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");
      final rate = job?.hourlyRate ?? 40.22;
      grandTotalNetHours += timerProvider.netMinutes / 60.0;
      grandTotalBaseSalary += (timerProvider.netMinutes / 60.0) * rate;
      grandTotalTips += timerProvider.tips;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shiftly',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'לוח שנה',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.work_outline_rounded),
            tooltip: 'הגדרות עבודה',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkConfigScreen()),
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
      body: Column(
        children: [
          if (timerProvider.startTime != null) _ActiveTimerBanner(timer: timerProvider),
          Expanded(
            child: groupedShifts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
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
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      100,
                    ), // Added bottom padding to avoid FAB and system bars
                    itemCount: groupedShifts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _GrandTotalCard(
                          totalHours: grandTotalNetHours,
                          totalBase: grandTotalBaseSalary,
                          totalTips: grandTotalTips,
                        );
                      }
                      final monthKey = groupedShifts.keys.elementAt(index - 1);
                      final shifts = groupedShifts[monthKey]!;
                      // Keep the latest month expanded by default
                      return _MonthExpansionSection(
                        monthKey: monthKey,
                        shifts: shifts,
                        initiallyExpanded: index == 1,
                      );
                    },
                  ),
          ),
        ],
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

class _ActiveTimerBanner extends StatelessWidget {
  final TimerProvider timer;

  const _ActiveTimerBanner({required this.timer});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.read<ShiftProvider>();
    final job = shiftProvider.getJobTypeById(timer.jobTypeId ?? "");
    final pay = timer.calculateLivePay(job?.hourlyRate ?? 40.22);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final d = timer.elapsed;
    final timeStr =
        "${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddShiftScreen(initialTabIndex: 0),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: timer.isOnBreak
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: timer.isOnBreak
                ? Colors.orange.shade300
                : Colors.blue.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              timer.isOnBreak
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: timer.isOnBreak
                  ? Colors.orange.shade800
                  : Colors.blue.shade800,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.isOnBreak
                        ? 'משמרת בהפסקה...'
                        : 'משמרת פעילה: ${job?.name ?? ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: timer.isOnBreak
                          ? Colors.orange.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    'זמן: $timeStr | ₪${pay.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: timer.isOnBreak
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: timer.isOnBreak ? Colors.orange : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _GrandTotalCard extends StatelessWidget {
  final double totalHours;
  final double totalBase;
  final double totalTips;

  const _GrandTotalCard({
    required this.totalHours,
    required this.totalBase,
    required this.totalTips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'סה"כ הצטבר (כללי)',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "₪${(totalBase + totalTips).toStringAsFixed(2)}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HeaderInfoItem(
                    label: 'שעות',
                    value: totalHours.toStringAsFixed(2),
                  ),
                  _VerticalDivider(),
                  _HeaderInfoItem(
                    label: 'שכר בסיס',
                    value: "₪${totalBase.toStringAsFixed(2)}",
                  ),
                  _VerticalDivider(),
                  _HeaderInfoItem(
                    label: 'טיפים',
                    value: "₪${totalTips.toStringAsFixed(2)}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
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

    // Check if timer (active or paused) belongs to this month
    final timerProvider = context.watch<TimerProvider>();
    if (timerProvider.startTime != null &&
        timerProvider.startTime!.year == year &&
        timerProvider.startTime!.month == date.month) {
      final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");
      final rate = job?.hourlyRate ?? 40.22;
      totalNetHours += timerProvider.netMinutes / 60.0;
      totalBaseSalary += (timerProvider.netMinutes / 60.0) * rate;
      totalTips += timerProvider.tips;
    }

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
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
            "₪${(totalBaseSalary + totalTips).toStringAsFixed(2)} סה\"כ | ${totalNetHours.toStringAsFixed(2)} שעות",
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
    final settings = context.watch<SettingsProvider>();
    final job = shiftProvider.getJobTypeById(shift.jobTypeId);
    final rate = job?.hourlyRate ?? 40.22;
    final pay = shift.calculateTotalPay(rate);

    String breakInfo = "";
    if ((shift.breakType ?? BreakType.none) == BreakType.paid) {
      breakInfo =
          " (${settings.paidBreakDurationMinutes.toStringAsFixed(0)} דק' בתשלום)";
    } else if ((shift.breakType ?? BreakType.none) == BreakType.unpaid) {
      breakInfo =
          " (${(shift.unpaidBreakMinutes ?? settings.unpaidBreakDurationMinutes).toStringAsFixed(0)} דק' ללא תשלום)";
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

        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('משמרת מיום $dateStr נמחקה'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 4500),
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
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
            "${shift.netHours.toStringAsFixed(2)} ש'",
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
