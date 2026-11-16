import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config_parser.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';

/// Checks on the REAL bundled questionnaire, so a mistake in the file fails
/// the tests long before it reaches a phone.
void main() {
  late QuestionnaireConfig config;

  setUpAll(() {
    final raw = File(AssetQuestionnaireRepository.assetPath).readAsStringSync();
    config = const QuestionnaireConfigParser().parse(jsonDecode(raw));
  });

  test('loads with 5 chapters and 33 questions', () {
    expect(config.chapters.map((c) => c.id), [1, 2, 3, 4, 5]);
    expect(config.fields, hasLength(33));
  });

  test('each gender is asked 31 questions', () {
    for (final g in Gender.values) {
      expect(config.fields.where((f) => f.isAskedTo(g)), hasLength(31));
    }
    expect(config.field('hijab')!.gender, Gender.female);
    expect(config.field('open_to_second_wife')!.gender, Gender.female);
    expect(config.field('beard')!.gender, Gender.male);
    expect(config.field('partner_hijab')!.gender, Gender.male);
  });

  test('every key the code depends on exists', () {
    for (final key in FieldKeys.all) {
      expect(config.field(key), isNotNull, reason: 'missing "$key"');
    }
  });

  test('partner age uses the same bounds as age', () {
    final age = config.field(FieldKeys.age)!;
    final partner = config.field(FieldKeys.partnerAge)!;
    expect(partner.input, InputType.range);
    expect((partner.min, partner.max), (age.min, age.max));
    expect(partner.suggest.keys, containsAll(Gender.values));
  });

  test('private answers are never on the card', () {
    const private = [
      'partner_age',
      'partner_location',
      'partner_practice',
      'partner_hijab',
      'must_haves',
      'has_deal_breakers',
      'deal_breakers',
      'open_to_second_wife',
    ];
    for (final key in private) {
      expect(
        config.field(key)!.visibility,
        FieldVisibility.khalty,
        reason: key,
      );
    }
  });

  test('the six new questions are present and flagged for Arabic review', () {
    const added = [
      'languages',
      'height_cm',
      'sect',
      'marriage_timeline',
      'family_involvement',
      'open_to_second_wife',
    ];
    for (final key in added) {
      expect(config.field(key)!.needsReview, {AppLanguage.ar}, reason: key);
    }
    expect(config.field('languages')!.input, InputType.multi);
    expect(config.field('languages')!.allowText, isTrue);
    expect(config.field('height_cm')!.optional, isTrue);
  });

  test('every question and option resolves to text for every user', () {
    for (final f in config.fields) {
      for (final g in Gender.values.where(f.isAskedTo)) {
        for (final lang in AppLanguage.values) {
          expect(f.question.resolve(lang, g), isNotEmpty);
          expect(f.why.resolve(lang, g), isNotEmpty);
          for (final o in f.optionsFor(g)) {
            expect(o.label.resolve(lang, g), isNotEmpty);
          }
        }
      }
    }
  });

  test('the repository loads the same file from the app bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loaded = await AssetQuestionnaireRepository().load();
    expect(loaded.fields.map((f) => f.key), config.fields.map((f) => f.key));
  });
}
