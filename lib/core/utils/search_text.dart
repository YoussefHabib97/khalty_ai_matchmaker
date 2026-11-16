import 'package:khalty_ai_matchmaker/core/utils/digits.dart';

final _arabicMarks = RegExp('[ً-ٰٟـ]'); // harakat + tatweel
final _latinMarks = RegExp('[̀-ͯ]');

const _latinFolds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'å': 'a', 'ã': 'a', //
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
  'õ': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y',
};

/// Makes text comparable for search, so small spelling differences don't
/// matter: lower case, no diacritics or tatweel, Arabic letter variants
/// unified (أ إ آ ٱ → ا, ة → ه, ى → ي, ؤ → و, ئ → ي), Arabic digits as 0-9.
String normalizeForSearch(String text) {
  var s = normalizeDigits(text.toLowerCase().trim())
      .replaceAll(_arabicMarks, '')
      .replaceAll(_latinMarks, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  for (final MapEntry(:key, :value) in _latinFolds.entries) {
    s = s.replaceAll(key, value);
  }
  return s;
}
