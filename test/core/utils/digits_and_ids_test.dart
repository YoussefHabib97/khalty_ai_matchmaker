import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/digits.dart';
import 'package:khalty_ai_matchmaker/core/utils/ids.dart';

void main() {
  group('normalizeDigits', () {
    test('converts Arabic-Indic and Extended Arabic-Indic digits', () {
      expect(normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(normalizeDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('leaves other characters untouched', () {
      expect(normalizeDigits('عمري ٢٩ year 5'), 'عمري 29 year 5');
    });
  });

  group('parseLocalizedInt', () {
    test('parses any digit set, ignoring surrounding spaces', () {
      expect(parseLocalizedInt('29'), 29);
      expect(parseLocalizedInt('٢٩'), 29);
      expect(parseLocalizedInt(' ۲۹ '), 29);
    });

    test('returns null for non-integers', () {
      expect(parseLocalizedInt(''), isNull);
      expect(parseLocalizedInt('29a'), isNull);
      expect(parseLocalizedInt('2.5'), isNull);
    });
  });

  test('newId returns distinct 32-char hex ids', () {
    final ids = {for (var i = 0; i < 100; i++) newId()};
    expect(ids, hasLength(100));
    expect(ids.every(RegExp(r'^[0-9a-f]{32}$').hasMatch), isTrue);
  });
}
