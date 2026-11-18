import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_card.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_card_builder.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();
  QuestionnaireEngine engine(Gender g) => QuestionnaireEngine(config, g);

  final photo = ProfilePhoto(
    id: 'p1',
    localPath: 'photos/p1.jpg',
    addedAt: DateTime.utc(2026, 11, 18),
  );

  /// A finished profile, with [overrides] applied to the answers.
  UserProfile profile(
    Gender gender, {
    Map<String, AnswerValue> overrides = const {},
  }) {
    final base = profileAt(OnboardingStage.complete, gender: gender);
    return base.copyWith(
      answers: QuestionnaireAutofill.answerAll(
        engine(gender),
        overrides: overrides,
      ),
    );
  }

  ProfileCard cardOf(UserProfile p) =>
      ProfileCardBuilder.of(p, engine(p.gender));

  Iterable<String> keysOn(ProfileCard card) =>
      card.sections.expand((s) => s.items).map((i) => i.field.key);

  group('private answers never reach the card', () {
    for (final gender in Gender.values) {
      test('${gender.name}: no "khalty" question, all answered', () {
        final p = profile(gender);
        final e = engine(gender);
        final private = [
          for (final f in e.fields)
            if (f.visibility == FieldVisibility.khalty) f.key,
        ];
        // They were really answered, so leaving them out is the builder's doing.
        expect(private, isNotEmpty);
        for (final key in private) {
          expect(e.effective(key, p.answers), isNotNull, reason: key);
        }

        final card = cardOf(p);
        for (final item in card.sections.expand((s) => s.items)) {
          expect(item.field.visibility, FieldVisibility.card);
        }
        expect(keysOn(card), isNot(anyElement(isIn(private))));
      });
    }

    test("Khalty's impressions, the brief and the introduction stay off", () {
      final p = profile(Gender.female).copyWith(
        analysis: IntakeAnalysis(
          aboutMe: 'I teach children.',
          traits: const [Trait(label: 'Warm', reason: 'Secret')],
          brief: 'Private brief',
          language: AppLanguage.en,
          generatedAt: sessionTime,
        ),
      );
      final card = cardOf(p);
      // The bio is the only text taken from the analysis.
      expect(card.aboutMe, 'I teach children.');
      final shown = [
        card.aboutMe,
        for (final item in card.sections.expand((s) => s.items))
          '${item.value}',
      ].join(' ');
      expect(shown, isNot(contains('Private brief')));
      expect(shown, isNot(contains('Warm')));
      expect(shown, isNot(contains('Hello'))); // the self-introduction
    });
  });

  test('header: name, age and place; not repeated as answers', () {
    final card = cardOf(profile(Gender.female));
    expect(card.name, 'Sara');
    expect(card.age, 30);
    expect(card.city, 'Something');
    expect(card.countryIso, 'SA');
    expect(
      keysOn(card),
      isNot(anyElement(isIn(ProfileCardBuilder.headerKeys))),
    );
    expect(keysOn(card), containsAll(['nationality', 'prayer', 'hijab']));
    expect(card.sections.map((s) => s.chapter.id), [1, 2, 3]);
  });

  test('answers that say nothing stay off', () {
    final card = cardOf(
      profile(
        Gender.male,
        overrides: {
          'height_cm': const SkippedAnswer(),
          'employment': const ChoiceAnswer('studying'),
        },
      ),
    );
    final keys = keysOn(card);
    expect(keys, isNot(contains('height_cm'))); // skipped
    expect(keys, isNot(contains('second_nationality'))); // "no"
    expect(keys, isNot(contains('work'))); // would repeat "Studying"
    expect(keys, contains('employment'));
    // Derived from "never married", and worth knowing.
    expect(keys, contains('children_now'));
  });

  test("a man's main photo is shown", () {
    final card = cardOf(profile(Gender.male).copyWith(photos: [photo]));
    expect(card.photo, photo);
    expect(card.photoNote, CardPhotoNote.visibleToSuggested);
  });

  test("a woman's photo is never on the card before she accepts", () {
    final woman = profile(Gender.female).copyWith(photos: [photo]);
    final private = cardOf(woman);
    expect(private.photo, isNull);
    expect(private.photoNote, CardPhotoNote.keptPrivate);

    final sharing = cardOf(woman.copyWith(sharePhotoWithMatch: true));
    expect(sharing.photo, isNull);
    expect(sharing.photoNote, CardPhotoNote.sharedAfterAccept);
  });

  test('no photo: the silhouette, styled from the answers', () {
    final card = cardOf(
      profile(Gender.female, overrides: {'hijab': const ChoiceAnswer('niqab')}),
    );
    expect(card.photo, isNull);
    expect(card.photoNote, CardPhotoNote.none);
    expect(card.silhouette, SilhouetteStyle.niqab);
  });

  test('an empty bio is left out', () {
    final card = cardOf(profile(Gender.female).copyWith(aboutMe: '  '));
    expect(card.aboutMe, isNull);
  });
}
