import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/country_search.dart';
import 'package:khalty_ai_matchmaker/core/utils/search_text.dart';

void main() {
  group('normalizeForSearch', () {
    test('unifies Arabic letter variants and removes marks', () {
      expect(normalizeForSearch('السعودية'), normalizeForSearch('السعوديه'));
      expect(normalizeForSearch('أَلمانيا'), normalizeForSearch('المانيا'));
      expect(normalizeForSearch('إيران'), 'ايران');
      expect(normalizeForSearch('مـصـر'), 'مصر'); // tatweel
      expect(normalizeForSearch('موسى'), 'موسي');
    });

    test('lower-cases and folds Latin accents', () {
      expect(normalizeForSearch('Côte d’Ivoire'), startsWith('cote'));
      expect(normalizeForSearch('  SAUDI '), 'saudi');
    });
  });

  group('searchCountries', () {
    List<String> codes(String q, [AppLanguage l = AppLanguage.en]) =>
        searchCountries(q, l).map((c) => c.iso2).toList();

    test('finds by English or Arabic name, spelling-tolerant', () {
      expect(codes('saudi'), contains('SA'));
      expect(codes('السعوديه', AppLanguage.ar), contains('SA'));
      expect(codes('مصر', AppLanguage.ar), contains('EG'));
    });

    test('finds by dialling code or ISO code', () {
      expect(codes('+966'), ['SA']);
      expect(codes('eg'), contains('EG'));
    });

    test('names starting with the query come first', () {
      expect(codes('united').first, startsWith('A')); // United Arab Emirates
      expect(codes('jordan').first, 'JO');
    });

    test('no match gives an empty list', () {
      expect(codes('zzzz'), isEmpty);
    });

    test('common countries come in their fixed order', () {
      expect(commonCountries().take(3).map((c) => c.iso2), ['SA', 'AE', 'KW']);
    });
  });
}
