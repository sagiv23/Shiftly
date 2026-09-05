import 'package:intl/intl.dart';
import '../models/shift.dart';
import 'package:uuid/uuid.dart';

class ShiftParser {
  static final Uuid _uuid = const Uuid();

  /// Parses strings like "24.6 - 17:30 - 23:00" or "22.7 - 07:00 - 13:00 + 50 tip"
  static Shift? parse(String input, String jobTypeId, {double breakMinutes = 0}) {
    try {
      input = input.trim();
      
      // Regex to capture Date, StartTime, EndTime, and optional Tips
      // Format: DD.MM - HH:mm - HH:mm [+ tips tip]
      final regex = RegExp(
        r'(\d{1,2}\.\d{1,2})\s*-\s*(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})(?:\s*\+\s*(\d+))?',
        caseSensitive: false,
      );

      final match = regex.firstMatch(input);
      if (match == null) return null;

      final dateStr = match.group(1)!;
      final startTimeStr = match.group(2)!;
      final endTimeStr = match.group(3)!;
      final tipsStr = match.group(4);

      final now = DateTime.now();
      final dateParts = dateStr.split('.');
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      
      final date = DateTime(now.year, month, day);

      final startTimeParts = startTimeStr.split(':');
      final start = DateTime(date.year, date.month, date.day, 
          int.parse(startTimeParts[0]), int.parse(startTimeParts[1]));

      final endTimeParts = endTimeStr.split(':');
      var end = DateTime(date.year, date.month, date.day, 
          int.parse(endTimeParts[0]), int.parse(endTimeParts[1]));

      // Handle overnight shift
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      final tips = tipsStr != null ? double.tryParse(tipsStr) ?? 0.0 : 0.0;

      return Shift(
        id: _uuid.v4(),
        date: date,
        startTime: start,
        endTime: end,
        jobTypeId: jobTypeId,
        tips: tips,
        breakMinutes: breakMinutes,
      );
    } catch (e) {
      return null;
    }
  }
}
