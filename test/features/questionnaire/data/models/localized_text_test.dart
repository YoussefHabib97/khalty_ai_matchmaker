import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/localized_text.dart';

void main() {
  final text = LocalizedText.fromJson({
    'en': 'How old are you, {name}?',
    'ar': {
      'male': 'كم عمرك يا {name}؟ اكتب',
      'female': 'كم عمرك يا {name}؟ اكتبي',
    },
  }, 'test');

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
    final acks = LocalizedTextList.fromJson({
      'en': ['Thanks', 'Lovely'],
      'ar': ['شكرًا'],
    }, 'acks');
    expect(acks.forLanguage(AppLanguage.en), ['Thanks', 'Lovely']);
    expect(acks.forLanguage(AppLanguage.ar), ['شكرًا']);
  });
}
