import 'package:uuid/uuid.dart';

import '../models/break_type.dart';
import '../models/shift.dart';

class ShiftParser {
  static final Uuid _uuid = const Uuid();

  /// Parses strings like:
  /// "24.6.2026 - 17:00 - 23:00 ללא + 50"
  /// "24.6 - 17:00 - 23:00 45 + 50"
  static Shift? parse(String input, String jobTypeId) {
    try {
      input = input.trim();

      // Updated Regex to include optional break description before the '+'
      // Format: DD.MM[.YYYY] - HH:mm - HH:mm [Break Description] [+ tips]
      final regex = RegExp(
        r'(\d{1,2}\.\d{1,2}(?:\.\d{2,4})?)\s*-\s*(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\s*(.*?)(?:\s*\+\s*(\d+))?\s*$',
        caseSensitive: false,
      );

      final match = regex.firstMatch(input);
      if (match == null) return null;

      final dateStr = match.group(1)!;
      final startTimeStr = match.group(2)!;
      final endTimeStr = match.group(3)!;
      final breakStr = match.group(4)?.trim() ?? "";
      final tipsStr = match.group(5);

      final now = DateTime.now();
      final dateParts = dateStr.split('.');
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);

      int year = now.year;
      if (dateParts.length == 3) {
        year = int.parse(dateParts[2]);
        if (year < 100) year += 2000;
      }

      final date = DateTime(year, month, day);

      final startTimeParts = startTimeStr.split(':');
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final endTimeParts = endTimeStr.split(':');
      var end = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      // Determine BreakType from text
      BreakType breakType = BreakType.none;

      if (breakStr.contains('45 דקות')) {
        breakType = BreakType.fortyFiveMinUnpaid;
      } else if (breakStr.contains('20 דקות')) {
        breakType = BreakType.twentyMinPaid;
      } else if (breakStr.contains('ללא')) {
        breakType = BreakType.none;
      }

      final tips = tipsStr != null ? double.tryParse(tipsStr) ?? 0.0 : 0.0;

      return Shift(
        id: _uuid.v4(),
        date: date,
        startTime: start,
        endTime: end,
        jobTypeId: jobTypeId,
        tips: tips,
        breakType: breakType,
      );
    } catch (e) {
      return null;
    }
  }
}
