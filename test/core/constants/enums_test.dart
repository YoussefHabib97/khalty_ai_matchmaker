import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';

void main() {
  test('Gender parses by name and rejects unknown values', () {
    expect(Gender.fromName('male'), Gender.male);
    expect(Gender.fromName('female'), Gender.female);
    expect(() => Gender.fromName('1'), throwsFormatException);
    expect(() => Gender.fromName(null), throwsFormatException);
  });

  test('AppLanguage parses codes and falls back to English', () {
    expect(AppLanguage.fromCode('ar'), AppLanguage.ar);
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode('fr'), AppLanguage.en);
    expect(AppLanguage.ar.code, 'ar');
  });
}
