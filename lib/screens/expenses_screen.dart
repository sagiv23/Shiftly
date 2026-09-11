import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftly/models/expense.dart';
import 'package:shiftly/providers/shift_provider.dart';
import 'package:shiftly/theme/app_theme.dart';
import 'package:shiftly/utils/ui_utils.dart';
import 'package:uuid/uuid.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _showExpenseDialog(BuildContext context, [Expense? expense]) {
    final descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    DateTime selectedDate = expense?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(expense == null ? 'הוספת הוצאה' : 'עריכת הוצאה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.blue,
                  ),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'תיאור ההוצאה (למשל: אוטובוס)',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'סכום (₪)',
                    prefixIcon: Icon(Icons.sell_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                final desc = descriptionController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (desc.isEmpty) {
                  UIUtils.showSnackBar(
                    context,
                    'נא להזין תיאור',
                    isError: true,
                  );
                  return;
                }
                if (amount <= 0) {
                  UIUtils.showSnackBar(
                    context,
                    'הסכום חייב להיות גדול מ-0',
                    isError: true,
                  );
                  return;
                }

                final confirmed = await UIUtils.showConfirmDialog(
                  context: context,
                  title: expense == null ? 'הוספת הוצאה' : 'עדכון הוצאה',
                  content:
                      'האם לשמור את ההוצאה "$desc" בסך ${UIUtils.formatCurrency(amount)}?',
                );

                if (confirmed != true) return;

                if (!context.mounted) return;

                final provider = context.read<ShiftProvider>();
                if (expense == null) {
                  provider.addExpense(
                    Expense(
                      id: const Uuid().v4(),
                      date: selectedDate,
                      description: desc,
                      amount: amount,
                    ),
                  );
                } else {
                  expense.description = desc;
                  expense.amount = amount;
                  expense.date = selectedDate;
                  provider.updateExpense(expense);
                }
                Navigator.pop(ctx);
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final groupedExpenses = shiftProvider.expensesGroupedByMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ניהול הוצאות',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: groupedExpenses.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: AppTheme.expense.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Text(
                        'אין הוצאות רשומות',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceSm,
                  AppTheme.spaceXs,
                  AppTheme.spaceSm,
                  120, // Increased for ad space and system navigation
                ),
                itemCount: groupedExpenses.length,
                itemBuilder: (context, index) {
                  final monthKey = groupedExpenses.keys.elementAt(index);
                  final expenses = groupedExpenses[monthKey]!;
                  return _MonthExpenseSection(
                    monthKey: monthKey,
                    expenses: expenses,
                    onEdit: (e) => _showExpenseDialog(context, e),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context),
        backgroundColor: AppTheme.expenseSoft,
        foregroundColor: Colors.white,
        label: const Text('הוצאה חדשה'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _MonthExpenseSection extends StatelessWidget {
  final String monthKey;
  final List<Expense> expenses;
  final Function(Expense) onEdit;

  const _MonthExpenseSection({
    required this.monthKey,
    required this.expenses,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse("$monthKey-01");
    final monthName = DateFormat.MMMM('he_IL').format(date);
    final totalMonthExpenses = expenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName ${date.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              Text(
                'סה"כ: ${UIUtils.formatCurrency(totalMonthExpenses)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.expenseSoft,
                ),
              ),
            ],
          ),
        ),
        ...expenses.map(
          (e) => _ExpenseTile(expense: e, onEdit: () => onEdit(e)),
        ),
        const Divider(),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;

  const _ExpenseTile({required this.expense, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.read<ShiftProvider>();
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.expense.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spaceMd),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppTheme.expenseSoft,
        ),
      ),
      confirmDismiss: (direction) async {
        return await UIUtils.showConfirmDialog(
          context: context,
          title: 'מחיקת הוצאה',
          content:
              'האם אתה בטוח שברצונך למחוק את ההוצאה "${expense.description}" בסך ${UIUtils.formatCurrency(expense.amount)}?',
          isDestructive: true,
          confirmLabel: 'מחק',
        );
      },
      onDismissed: (_) {
        shiftProvider.deleteExpense(expense.id);
        UIUtils.showSnackBar(
          context,
          'הוצאה "${expense.description}" נמחקה',
          action: SnackBarAction(
            label: 'ביטול',
            onPressed: () => shiftProvider.addExpense(expense),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onEdit,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.expense.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.money_off_rounded,
              color: AppTheme.expenseSoft,
              size: 20,
            ),
          ),
          title: Text(
            expense.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.date)),
          trailing: Text(
            UIUtils.formatCurrency(expense.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.expenseSoft,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
