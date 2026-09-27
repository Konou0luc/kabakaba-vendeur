import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _compact = NumberFormat.compact(locale: 'fr_FR');
  static final NumberFormat _amount = NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 0,
  );

  static String formatTickets(num amount, {String currency = 'FCFA'}) {
    return '${_amount.format(amount)} $currency';
  }

  static String formatCompact(num amount) {
    return _compact.format(amount);
  }

  static String formatCountdown(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PhoneFormatter {
  static String formatDisplay(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 4) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    if (digits.length <= 6) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4)}';
    }
    return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6)}';
  }

  static List<TextInputFormatter> get formatters => [
    FilteringTextInputFormatter.digitsOnly,
  ];
}
