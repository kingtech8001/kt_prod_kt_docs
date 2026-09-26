import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹ ',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateTimeFormat.format(date);
  }

  static String formatCurrency(num? amount) {
    if (amount == null) return '₹ 0';
    return _currencyFormat.format(amount);
  }

  static String formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat.decimalPattern('en_IN').format(value);
  }

  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static int daysUntil(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }
}
