import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/localized_text.dart';

void main() {
  const text = LocalizedText(
    en: GenderedText.same('How old are you, {name}?'),
    ar: GenderedText('كم عمرك يا {name}؟ اكتب', 'كم عمرك يا {name}؟ اكتبي'),
  );

  test('picks the language and the user\'s gender', () {
    expect(
      text.resolve(AppLanguage.en, Gender.female),
      'How old are you, {name}?',
    );
    expect(
      text.resolve(AppLanguage.ar, Gender.male),
      'كم عمرك يا {name}؟ اكتب',
    );
    expect(
      text.resolve(AppLanguage.ar, Gender.female),
      'كم عمرك يا {name}؟ اكتبي',
    );
  });

  test('fills placeholders and leaves missing ones as-is', () {
    expect(
      text.resolve(AppLanguage.en, Gender.male, vars: {'name': 'Ali'}),
      'How old are you, Ali?',
    );
    expect(
      text.resolve(AppLanguage.en, Gender.male, vars: {'detected': 'KSA'}),
      'How old are you, {name}?',
    );
  });

  test('knows whether a language is gendered', () {
    expect(text.en.isGendered, isFalse);
    expect(text.ar.isGendered, isTrue);
  });

  test('a list of texts per language', () {
    final acks = LocalizedTextList(en: ['Thanks', 'Lovely'], ar: ['شكرًا']);
    expect(acks.forLanguage(AppLanguage.en), ['Thanks', 'Lovely']);
    expect(acks.forLanguage(AppLanguage.ar), ['شكرًا']);
  });

  test('a list cycles by index and fills placeholders', () {
    final acks = LocalizedTextList(
      en: ['Thanks, {name}', 'Lovely'],
      ar: ['شكرًا'],
    );
    expect(
      acks.resolve(AppLanguage.en, 0, vars: {'name': 'Sara'}),
      'Thanks, Sara',
    );
    expect(acks.resolve(AppLanguage.en, 3), 'Lovely');
    expect(acks.resolve(AppLanguage.ar, 5), 'شكرًا');
  });
}
