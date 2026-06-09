import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String symbol = '৳';

  static String format(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final formatted = formatter.format(amount);
    if (showSymbol) return '$symbol$formatted';
    return formatted;
  }

  static String formatBn(double amount) {
    final en = format(amount, showSymbol: false);
    return '$symbol${_toBanglaDigits(en)}';
  }

  static String _toBanglaDigits(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], bn[i]);
    }
    return result;
  }
}

class DateFormatter {
  static String format(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatWithDay(DateTime date) {
    return DateFormat('EEEE, dd/MM/yyyy').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
