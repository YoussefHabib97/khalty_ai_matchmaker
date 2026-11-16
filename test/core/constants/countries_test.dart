import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';

void main() {
  test('about 245 countries with unique ISO codes', () {
    expect(kCountries.length, greaterThan(240));
    expect(kCountries.map((c) => c.iso2).toSet(), hasLength(kCountries.length));
  });

  test('every country has names in both languages and a numeric code', () {
    for (final c in kCountries) {
      expect(c.iso2, matches(RegExp(r'^[A-Z]{2}$')));
      expect(c.dialCode, matches(RegExp(r'^\d{1,4}$')), reason: c.iso2);
      expect(c.nameEn.trim(), isNotEmpty, reason: c.iso2);
      expect(c.nameAr.trim(), isNotEmpty, reason: c.iso2);
    }
  });

  test('every common country exists', () {
    for (final code in kCommonCountryCodes) {
      expect(countryByIso(code), isNotNull, reason: code);
    }
  });

  test('keeps the old app\'s reviewed names', () {
    expect(countryByIso('SA')!.nameAr, 'السعودية');
    expect(countryByIso('AE')!.nameAr, 'الإمارات');
    expect(countryByIso('PS')!.nameEn, 'Palestine');
  });

  test('lookup, names and flags', () {
    final sa = countryByIso('sa')!;
    expect(sa.dialCode, '966');
    expect(sa.name(AppLanguage.en), 'Saudi Arabia');
    expect(sa.name(AppLanguage.ar), 'السعودية');
    expect(sa.flag, '🇸🇦');
    expect(countryByIso('XX'), isNull);
  });
}
