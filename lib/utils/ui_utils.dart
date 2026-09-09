import 'package:flutter/material.dart';

class UIUtils {
  /// Formats a double value as currency with the ₪ symbol.
  /// Example: 100.5 -> "₪100.50"
  static String formatCurrency(double amount) {
    return '₪${amount.toStringAsFixed(2)}';
  }

  /// Returns a style for currency text, making it red if negative.
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
      return style.copyWith(color: Colors.red, fontWeight: FontWeight.bold);
    }
    if (positiveColor != null) {
      return style.copyWith(color: positiveColor);
    }
    return style;
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
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ?? (isDestructive ? Colors.red : null),
              foregroundColor: confirmColor != null || isDestructive
                  ? Colors.white
                  : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
