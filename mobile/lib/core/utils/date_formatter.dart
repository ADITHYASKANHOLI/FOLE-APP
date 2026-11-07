import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats duration in seconds to standard 'MM:SS' or 'HH:MM:SS'
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '00:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Formats ISO-8601 string to Asia/Kolkata readable date (e.g. '15 Nov 2026')
  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final utcDate = DateTime.parse(isoString).toUtc();
      // Apply Asia/Kolkata offset (+05:30)
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('d MMM yyyy').format(istDate);
    } catch (_) {
      return isoString;
    }
  }

  /// Formats ISO-8601 string to Asia/Kolkata readable date and time (e.g. '15 Nov 2026, 09:30 AM')
  static String formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final utcDate = DateTime.parse(isoString).toUtc();
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('d MMM yyyy, hh:mm a').format(istDate);
    } catch (_) {
      return isoString;
    }
  }
}
