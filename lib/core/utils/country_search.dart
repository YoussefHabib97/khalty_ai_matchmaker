import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/search_text.dart';

/// All countries sorted by their name in [language].
List<Country> countriesSortedFor(AppLanguage language) =>
    [...kCountries]
      ..sort((a, b) => a.name(language).compareTo(b.name(language)));

/// The common countries ([kCommonCountryCodes]), in that order.
List<Country> commonCountries() => [
  for (final code in kCommonCountryCodes) ?countryByIso(code),
];

/// Countries matching [query] by English or Arabic name (ignoring small
/// spelling differences), dialling code or ISO code. Names that start with
/// the query come first, then alphabetical in [language].
List<Country> searchCountries(String query, AppLanguage language) {
  final q = normalizeForSearch(query).replaceFirst('+', '');
  if (q.isEmpty) return countriesSortedFor(language);

  bool startsWith(Country c) =>
      normalizeForSearch(c.nameEn).startsWith(q) ||
      normalizeForSearch(c.nameAr).startsWith(q);

  final matches = [
    for (final c in countriesSortedFor(language))
      if (normalizeForSearch(c.nameEn).contains(q) ||
          normalizeForSearch(c.nameAr).contains(q) ||
          c.dialCode.startsWith(q) ||
          c.iso2.toLowerCase() == q)
        c,
  ];
  return [
    ...matches.where(startsWith),
    ...matches.where((c) => !startsWith(c)),
  ];
}
