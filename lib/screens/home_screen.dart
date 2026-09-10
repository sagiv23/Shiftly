import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/models/break_type.dart';
import 'package:shiftly/models/shift.dart';
import 'package:shiftly/providers/settings_provider.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/providers/timer_provider.dart';
import 'package:shiftly/screens/add_shift_screen.dart';
import 'package:shiftly/screens/calendar_screen.dart';
import 'package:shiftly/screens/expenses_screen.dart';
import 'package:shiftly/screens/job_types_screen.dart';
import 'package:shiftly/screens/settings_screen.dart';
import 'package:shiftly/theme/app_theme.dart';
import 'package:shiftly/utils/ui_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final groupedShifts = shiftProvider.shiftsGroupedByMonth;

    double grandTotalNetHours = 0;
    double grandTotalBaseSalary = 0;
    double grandTotalTips = 0;
    double grandTotalExpenses = 0;

    for (var shift in shiftProvider.shifts) {
      final job = shiftProvider.getJobTypeById(shift.jobTypeId);
      final rate = shift.hourlyRate ?? job?.getRateForDate(shift.date) ?? 40.22;
      grandTotalNetHours += shift.netHours;
      grandTotalBaseSalary += shift.netHours * rate;
      grandTotalTips += shift.tips;
    }

    for (var expense in shiftProvider.expenses) {
      grandTotalExpenses += expense.amount;
    }

    if (timerProvider.startTime != null) {
      final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");
      final rate = job?.getRateForDate(timerProvider.startTime!) ?? 40.22;
      grandTotalNetHours += timerProvider.netMinutes / 60.0;
      grandTotalBaseSalary += (timerProvider.netMinutes / 60.0) * rate;
      grandTotalTips += timerProvider.tips;
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'לוח שנה',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded),
              tooltip: 'הוצאות',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              ),
            ),
          ],
        ),
        title: Text(
          'Shiftly',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
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
          const SizedBox(width: AppTheme.spaceXs),
        ],
      ),
      body: Column(
        children: [
          if (timerProvider.startTime != null)
            _ActiveTimerBanner(timer: timerProvider),
          Expanded(
            child: groupedShifts.isEmpty && timerProvider.startTime == null
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceSm,
                      AppTheme.spaceXs,
                      AppTheme.spaceSm,
                      100,
                    ),
                    itemCount: groupedShifts.isEmpty
                        ? 1
                        : groupedShifts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _GrandTotalCard(
                          totalHours: grandTotalNetHours,
                          totalBase: grandTotalBaseSalary,
                          totalTips: grandTotalTips,
                          totalExpenses: grandTotalExpenses,
                        );
                      }
                      final monthKey = groupedShifts.keys.elementAt(index - 1);
                      final shifts = groupedShifts[monthKey]!;
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
        label: const Text('משמרת חדשה'),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'הוסף משמרת',
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 56,
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'עדיין לא נרשמו משמרות',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'לחץ על "משמרת חדשה" כדי להתחיל',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
    final rate = timer.startTime != null
        ? (job?.getRateForDate(timer.startTime!) ?? 40.22)
        : (job?.hourlyRate ?? 40.22);
    final pay = timer.calculateLivePay(rate);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final d = timer.elapsed;
    final timeStr =
        "${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";

    final isBreak = timer.isOnBreak;
    final accent = isBreak ? AppTheme.warningSoft : AppTheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScalePress(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddShiftScreen(initialTabIndex: 0),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spaceSm,
          AppTheme.spaceXs,
          AppTheme.spaceSm,
          AppTheme.spaceSm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBreak
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBreak
                        ? 'משמרת בהפסקה...'
                        : 'משמרת פעילה: ${job?.name ?? ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? accent : accent.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'זמן: $timeStr  ·  ${UIUtils.formatCurrency(pay)}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
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
  final double totalExpenses;

  const _GrandTotalCard({
    required this.totalHours,
    required this.totalBase,
    required this.totalTips,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalBase + totalTips - totalExpenses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(
        bottom: AppTheme.spaceMd,
        top: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0EA5E9),
                  const Color(0xFF0369A1),
                  const Color(0xFF1E293B),
                ]
              : [
                  const Color(0xFF38BDF8),
                  const Color(0xFF0EA5E9),
                  const Color(0xFF0284C7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Stack(
          children: [
            // Soft glass overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                children: [
                  Text(
                    'סה"כ הצטבר (נטו פחות הוצאות)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    UIUtils.formatCurrency(net),
                    style: AppTheme.monoNumber.copyWith(
                      color: net < 0 ? const Color(0xFFFECACA) : Colors.white,
                      fontSize: 40,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
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
                          label: 'בסיס',
                          value: UIUtils.formatCurrency(totalBase),
                          amount: totalBase,
                        ),
                        _VerticalDivider(),
                        _HeaderInfoItem(
                          label: 'טיפים',
                          value: UIUtils.formatCurrency(totalTips),
                          amount: totalTips,
                        ),
                        _VerticalDivider(),
                        _HeaderInfoItem(
                          label: 'הוצאות',
                          value: UIUtils.formatCurrency(totalExpenses),
                          amount: -totalExpenses,
                        ),
                      ],
                    ),
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
  final double? amount;

  const _HeaderInfoItem({
    required this.label,
    required this.value,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: (amount ?? 0) < 0 ? const Color(0xFFFECACA) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
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
    double totalMonthExpenses = 0;

    for (var shift in shifts) {
      final job = shiftProvider.getJobTypeById(shift.jobTypeId);
      final rate = shift.hourlyRate ?? job?.getRateForDate(shift.date) ?? 40.22;
      totalNetHours += shift.netHours;
      totalBaseSalary += shift.netHours * rate;
      totalTips += shift.tips;
    }

    final allExpenses = shiftProvider.expensesGroupedByMonth[monthKey] ?? [];
    for (var expense in allExpenses) {
      totalMonthExpenses += expense.amount;
    }

    final date = DateTime.parse("$monthKey-01");
    final monthName = DateFormat.MMMM('he_IL').format(date);
    final year = date.year;

    final timerProvider = context.watch<TimerProvider>();
    if (timerProvider.startTime != null &&
        timerProvider.startTime!.year == year &&
        timerProvider.startTime!.month == date.month) {
      final job = shiftProvider.getJobTypeById(timerProvider.jobTypeId ?? "");
      final rate = job?.getRateForDate(timerProvider.startTime!) ?? 40.22;
      totalNetHours += timerProvider.netMinutes / 60.0;
      totalBaseSalary += (timerProvider.netMinutes / 60.0) * rate;
      totalTips += timerProvider.tips;
    }

    final net = totalBaseSalary + totalTips - totalMonthExpenses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusLg)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusLg)),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSm + 4,
            vertical: AppTheme.spaceXs,
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
          title: Text(
            "$monthName $year",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${UIUtils.formatCurrency(net)} סה\"כ נטו  ·  ${totalNetHours.toStringAsFixed(2)} שעות",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          children: [
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryItem(
                      label: 'בסיס',
                      value: UIUtils.formatCurrency(totalBaseSalary),
                      amount: totalBaseSalary,
                    ),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    _SummaryItem(
                      label: 'טיפים',
                      value: UIUtils.formatCurrency(totalTips),
                      amount: totalTips,
                      accent: AppTheme.profit,
                    ),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    _SummaryItem(
                      label: 'הוצאות',
                      value: UIUtils.formatCurrency(totalMonthExpenses),
                      amount: -totalMonthExpenses,
                    ),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    _SummaryItem(
                      label: 'נטו',
                      value: UIUtils.formatCurrency(net),
                      isBold: true,
                      amount: net,
                    ),
                  ],
                ),
              ),
            ),
            ...shifts.map((shift) => _ShiftTile(shift: shift)),
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
  final double? amount;
  final Color? accent;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.amount,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    Color? textColor;
    if ((amount ?? 0) < 0) {
      textColor = AppTheme.expense;
    } else if (isBold) {
      textColor = AppTheme.primaryDark;
    } else if (accent != null) {
      textColor = accent;
    }

    return Flexible(
      child: Column(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
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
    final rate = shift.hourlyRate ?? job?.getRateForDate(shift.date) ?? 40.22;
    final pay = shift.calculateTotalPay(rate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final breakType = shift.breakType ?? BreakType.none;

    return Dismissible(
      key: Key(shift.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceXs / 2,
        ),
        decoration: BoxDecoration(
          color: AppTheme.expense.withValues(alpha: isDark ? 0.2 : 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spaceMd),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppTheme.expenseSoft,
        ),
      ),
      confirmDismiss: (direction) async {
        final dateStr = DateFormat('dd/MM/yyyy').format(shift.date);
        return await UIUtils.showConfirmDialog(
          context: context,
          title: 'מחיקת משמרת',
          content: 'האם אתה בטוח שברצונך למחוק את המשמרת מיום $dateStr?',
          isDestructive: true,
          confirmLabel: 'מחק',
        );
      },
      onDismissed: (_) {
        final dateStr = DateFormat('dd/MM/yyyy').format(shift.date);
        shiftProvider.deleteShift(shift.id);

        UIUtils.showSnackBar(
          context,
          'משמרת מיום $dateStr נמחקה',
          action: SnackBarAction(
            label: 'ביטול',
            onPressed: () {
              shiftProvider.addShift(shift);
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceXs,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // Date badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.d().format(shift.date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryDark,
                            height: 1,
                          ),
                        ),
                        Text(
                          DateFormat.E('he_IL').format(shift.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppTheme.iconForJobName(job?.name),
                              size: 16,
                              color: AppTheme.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job?.name ?? 'לא ידוע',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${DateFormat.Hm().format(shift.startTime)} – ${DateFormat.Hm().format(shift.endTime)}  ·  ${shift.netHours.toStringAsFixed(2)} ש'",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (shift.tips > 0 || breakType != BreakType.none) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (shift.tips > 0)
                                _ShiftTag(
                                  label:
                                      '+${UIUtils.formatCurrency(shift.tips)}',
                                  icon: Icons.payments_outlined,
                                  color: AppTheme.profit,
                                ),
                              if (breakType == BreakType.paid)
                                _ShiftTag(
                                  label:
                                      "${settings.paidBreakDurationMinutes.toStringAsFixed(0)}' בתשלום",
                                  icon: Icons.timer_outlined,
                                  color: AppTheme.primary,
                                ),
                              if (breakType == BreakType.unpaid)
                                _ShiftTag(
                                  label:
                                      "${(shift.unpaidBreakMinutes ?? settings.unpaidBreakDurationMinutes).toStringAsFixed(0)}' הפסקה",
                                  icon: Icons.coffee_outlined,
                                  color: AppTheme.warningSoft,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  Text(
                    UIUtils.formatCurrency(pay),
                    style: UIUtils.getCurrencyStyle(
                      context,
                      pay,
                      positiveColor: AppTheme.primaryDark,
                      baseStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ShiftTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
