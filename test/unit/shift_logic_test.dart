import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/models/break_type.dart';
import 'package:shiftly/models/shift.dart';
import 'package:shiftly/services/shift_parser.dart';

void main() {
  group('Shift Model Logic', () {
    test('calculate duration correctly for normal shift', () {
      final start = DateTime(2026, 6, 24, 9, 0);
      final end = DateTime(2026, 6, 24, 17, 0);
      final shift = Shift(
        id: '1',
        date: start,
        startTime: start,
        endTime: end,
        jobTypeId: 'j1',
      );

      expect(shift.durationHours, 8.0);
      expect(shift.netHours, 8.0);
    });

    test('calculate duration correctly for overnight shift', () {
      final start = DateTime(2026, 6, 24, 22, 0);
      final end = DateTime(2026, 6, 25, 6, 0);
      final shift = Shift(
        id: '1',
        date: start,
        startTime: start,
        endTime: end,
        jobTypeId: 'j1',
      );

      expect(shift.durationHours, 8.0);
    });

    test('deduct break correctly', () {
      final start = DateTime(2026, 6, 24, 9, 0);
      final end = DateTime(2026, 6, 24, 19, 0);
      final shift = Shift(
        id: '1',
        date: start,
        startTime: start,
        endTime: end,
        jobTypeId: 'j1',
        breakType: BreakType.unpaid,
      );

      expect(shift.durationHours, 10.0);
      expect(shift.netHours, 9.25);
    });
  });

  group('ShiftParser', () {
    test('parse standard format correctly', () {
      const input = "24.6 - 17:30 - 23:00";
      final shift = ShiftParser.parse(input, 'j1');

      expect(shift, isNotNull);
      expect(shift!.startTime.hour, 17);
      expect(shift.startTime.minute, 30);
      expect(shift.endTime.hour, 23);
      expect(shift.endTime.minute, 0);
    });

    test('parse with tips correctly', () {
      const input = "22.7 - 07:00 - 13:00 + 50 tip";
      final shift = ShiftParser.parse(input, 'j1');

      expect(shift, isNotNull);
      expect(shift!.tips, 50.0);
    });

    test('handle invalid input gracefully', () {
      expect(ShiftParser.parse("invalid input", 'j1'), isNull);
    });
  });
}
