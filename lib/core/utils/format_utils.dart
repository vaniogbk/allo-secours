import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String formatPrice(double amount, {String currency = 'FCFA'}) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }

  static String formatWeight(double kg) =>
      kg < 1 ? '${(kg * 1000).toStringAsFixed(0)} g' : '${kg.toStringAsFixed(1)} kg';

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String truncate(String text, int maxLength) =>
      text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';

  static String generateTrackingCode() {
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString().substring(7);
    return 'LGT${now.year}$suffix'.toUpperCase();
  }
}