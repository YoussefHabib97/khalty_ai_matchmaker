const _arabicIndicZero = 0x0660; // ٠
const _extendedArabicIndicZero = 0x06F0; // ۰ (Persian/Urdu)
const _asciiZero = 0x30;

/// Converts Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits to
/// ASCII 0-9, leaving everything else untouched.
String normalizeDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9) {
      out.writeCharCode(_asciiZero + rune - _arabicIndicZero);
    } else if (rune >= _extendedArabicIndicZero &&
        rune <= _extendedArabicIndicZero + 9) {
      out.writeCharCode(_asciiZero + rune - _extendedArabicIndicZero);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Parses a whole number typed in any of the supported digit sets
/// (e.g. "29", "٢٩", " ۲۹ "). Returns null if it isn't a plain integer.
int? parseLocalizedInt(String input) =>
    int.tryParse(normalizeDigits(input).trim());
