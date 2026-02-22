/// Helper functions for formatting data for display.
class FormatHelper {
  FormatHelper._();

  /// Formats a DateTime to a string in yyyy-mm-dd format (e.g., "2026-01-26").
  /// Returns an empty string if the date is null.
  static String formatDateString(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}