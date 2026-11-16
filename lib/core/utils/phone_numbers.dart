import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/utils/digits.dart';

/// Shortest and longest national number accepted (without the country code).
const kMinNationalDigits = 6;
const kMaxNationalDigits = 12;

/// Builds an international (E.164) number such as `+966501234567` from what
/// the user typed for [country], or null if it can't be a valid number.
///
/// Accepts Arabic-Indic digits, spaces, dashes, dots and brackets; drops a
/// leading trunk `0` and a country code the user typed themselves (`+966…`,
/// `00966…`). This is a basic check; the SMS provider does the real one.
String? toE164(Country country, String typed) {
  final hadPlus = typed.trim().startsWith('+');
  var digits = normalizeDigits(typed).replaceAll(RegExp(r'\D'), '');
  final dial = country.dialCode;

  if (digits.startsWith('00$dial')) {
    digits = digits.substring(2 + dial.length);
  } else if (hadPlus) {
    if (!digits.startsWith(dial)) return null; // a different country's code
    digits = digits.substring(dial.length);
  }
  digits = digits.replaceFirst(RegExp(r'^0+'), '');

  if (digits.length < kMinNationalDigits ||
      digits.length > kMaxNationalDigits) {
    return null;
  }
  if (dial.length + digits.length > 15) return null;
  return '+$dial$digits';
}

/// The national part of [e164] if it starts with [country]'s code (used to
/// pre-fill the phone field), otherwise null.
String? nationalNumber(Country country, String e164) {
  final prefix = '+${country.dialCode}';
  return e164.startsWith(prefix) ? e164.substring(prefix.length) : null;
}
