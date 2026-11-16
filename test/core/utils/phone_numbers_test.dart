import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/utils/phone_numbers.dart';

void main() {
  final sa = countryByIso('SA')!;
  final us = countryByIso('US')!;
  final eg = countryByIso('EG')!;

  group('toE164', () {
    test('local Saudi number with a leading 0', () {
      expect(toE164(sa, '0501234567'), '+966501234567');
      expect(toE164(sa, '501234567'), '+966501234567');
    });

    test('ignores spaces, dashes, dots and brackets', () {
      expect(toE164(sa, '(050) 123-45.67'), '+966501234567');
    });

    test('accepts Arabic-Indic digits', () {
      expect(toE164(sa, '٠٥٠١٢٣٤٥٦٧'), '+966501234567');
      expect(toE164(sa, '۰۵۰۱۲۳۴۵۶۷'), '+966501234567');
    });

    test('accepts the country code typed by the user', () {
      expect(toE164(sa, '+966 50 123 4567'), '+966501234567');
      expect(toE164(sa, '00966501234567'), '+966501234567');
    });

    test('rejects another country\'s code', () {
      expect(toE164(sa, '+20 100 123 4567'), isNull);
    });

    test('rejects numbers that are too short or too long', () {
      expect(toE164(sa, '12345'), isNull);
      expect(toE164(sa, '1234567890123'), isNull);
      expect(toE164(sa, ''), isNull);
    });

    test('other countries', () {
      expect(toE164(us, '(202) 555-0147'), '+12025550147');
      expect(toE164(eg, '0100 123 4567'), '+201001234567');
    });
  });

  test('nationalNumber strips the matching country code', () {
    expect(nationalNumber(sa, '+966501234567'), '501234567');
    expect(nationalNumber(eg, '+966501234567'), isNull);
  });
}
