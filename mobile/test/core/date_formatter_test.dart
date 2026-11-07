import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter - Duration Formatting', () {
    test('formats null or 0 seconds gracefully', () {
      expect(DateFormatter.formatDuration(null), '00:00');
      expect(DateFormatter.formatDuration(0), '00:00');
      expect(DateFormatter.formatDuration(-10), '00:00');
    });

    test('formats MM:SS correctly', () {
      expect(DateFormatter.formatDuration(65), '01:05');
      expect(DateFormatter.formatDuration(599), '09:59');
      expect(DateFormatter.formatDuration(2740), '45:40');
    });

    test('formats HH:MM:SS correctly', () {
      expect(DateFormatter.formatDuration(3600), '01:00:00');
      expect(DateFormatter.formatDuration(3665), '01:01:05');
      expect(DateFormatter.formatDuration(7325), '02:02:05');
    });
  });

  group('DateFormatter - Date & Time Formatting (Asia/Kolkata)', () {
    test('formats ISO UTC date to Asia/Kolkata (+05:30)', () {
      // 2026-11-07T14:30:00Z + 5h30m = 2026-11-07 20:00 (8:00 PM)
      final formattedDate = DateFormatter.formatDate('2026-11-07T14:30:00Z');
      expect(formattedDate, '7 Nov 2026');

      final formattedDateTime =
          DateFormatter.formatDateTime('2026-11-07T14:30:00Z');
      expect(formattedDateTime, contains('7 Nov 2026'));
      expect(formattedDateTime, contains('08:00 PM'));
    });

    test('handles date rollover into next day in IST', () {
      // 2026-11-07T20:00:00Z + 5h30m = 2026-11-08 01:30 AM
      final formattedDate = DateFormatter.formatDate('2026-11-07T20:00:00Z');
      expect(formattedDate, '8 Nov 2026');

      final formattedDateTime =
          DateFormatter.formatDateTime('2026-11-07T20:00:00Z');
      expect(formattedDateTime, '8 Nov 2026, 01:30 AM');
    });

    test('handles null or empty gracefully', () {
      expect(DateFormatter.formatDate(null), '');
      expect(DateFormatter.formatDate(''), '');
      expect(DateFormatter.formatDateTime(null), '');
      expect(DateFormatter.formatDateTime(''), '');
    });
  });
}
