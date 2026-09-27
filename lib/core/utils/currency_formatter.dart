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

/// Numéros togolais : 8 chiffres locaux, indicatif `+228`.
class PhoneFormatter {
  PhoneFormatter._();

  static const localDigits = 8;

  /// Chiffres nus, quelle que soit la façon dont le numéro a été saisi ou
  /// renvoyé par l'API (`+228 90 12 34 56`, `0022890123456`, `90123456`).
  static String digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Groupé par deux, pour l'affichage : `90 12 34 56`.
  static String formatDisplay(String value) {
    final digits = digitsOf(value);
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 2) {
      groups.add(digits.substring(i, (i + 2).clamp(0, digits.length)));
    }
    return groups.join(' ');
  }

  static bool isValidLocal(String value) =>
      digitsOf(value).length == localDigits;

  /// Format attendu par l'API (`@IsPhoneNumber` côté NestJS).
  ///
  /// Tolère un numéro déjà préfixé par l'indicatif pays, sinon on enverrait
  /// `+22822890123456` dès que le vendeur colle un numéro international.
  static String toE164(String value) {
    var digits = digitsOf(value);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('228')) return '+$digits';
    return '+228$digits';
  }
}

/// Applique le groupage par deux pendant la frappe, en gardant le curseur à
/// la bonne place — un `onChanged` qui réécrit le contrôleur le renvoie en
/// fin de champ dès qu'on corrige un chiffre au milieu.
class TogoPhoneInputFormatter extends TextInputFormatter {
  const TogoPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = PhoneFormatter.digitsOf(
      newValue.text.substring(0, cursor),
    ).length;

    final allDigits = PhoneFormatter.digitsOf(newValue.text);
    final digits = allDigits.length > PhoneFormatter.localDigits
        ? allDigits.substring(0, PhoneFormatter.localDigits)
        : allDigits;
    final formatted = PhoneFormatter.formatDisplay(digits);

    // Le curseur se replace après le n-ième chiffre, espaces compris.
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != ' ') seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
