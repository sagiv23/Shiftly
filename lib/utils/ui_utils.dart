import 'package:flutter/material.dart';
import 'package:shiftly/theme/app_theme.dart';

class UIUtils {
  /// Formats a double value as currency with the ₪ symbol.
  /// Example: 100.5 -> "₪100.50"
  static String formatCurrency(double amount) {
    return '₪${amount.toStringAsFixed(2)}';
  }

  /// Returns a style for currency text using semantic profit/expense colors.
  static TextStyle getCurrencyStyle(
    BuildContext context,
    double amount, {
    TextStyle? baseStyle,
    Color? positiveColor,
  }) {
    var style =
        baseStyle ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();
    if (amount < 0) {
      return style.copyWith(
        color: AppTheme.expense,
        fontWeight: FontWeight.bold,
      );
    }
    if (positiveColor != null) {
      return style.copyWith(color: positiveColor);
    }
    return style;
  }

  /// Shows a single, themed SnackBar — clears any current one first.
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final colorScheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: colorScheme.onError) : null,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        backgroundColor: isError ? colorScheme.error : null,
        action: action,
      ),
    );
  }

  /// Shows a consistent confirmation dialog across the app.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = 'אישור',
    String cancelLabel = 'ביטול',
    Color? confirmColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ?? (isDestructive ? AppTheme.expenseSoft : null),
              foregroundColor: confirmColor != null || isDestructive
                  ? Colors.white
                  : null,
              minimumSize: const Size(88, 44),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
