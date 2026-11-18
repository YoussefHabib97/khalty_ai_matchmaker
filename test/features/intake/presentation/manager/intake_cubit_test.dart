import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();
  QuestionnaireEngine engineFor(Gender g) => QuestionnaireEngine(config, g);
  final now = DateTime.utc(2026, 11, 17, 9);
  late ProfileRepository profiles;

  /// A cubit for a user (woman by default) who has given [answers].
  Future<IntakeCubit> build({
    Answers? answers,
    Gender gender = Gender.female,
    String deviceCountry = 'AE',
  }) async {
    final repo = LocalProfileRepository(await mockPrefs());
    addTearDown(repo.dispose);
    final profile = profileAt(OnboardingStage.needsIntake, gender: gender);
    await repo.save(profile.copyWith(answers: answers));
    profiles = repo;
    final cubit = IntakeCubit(
      profiles: profiles,
      engineFor: engineFor,
      deviceCountryIso: deviceCountry,
      now: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// Sample answers to every question before [key] (in this gender's order).
  Answers answeredUntil(String key, {Gender gender = Gender.female}) {
    final engine = engineFor(gender);
    var answers = Answers();
    for (
      var f = engine.nextField(answers);
      f != null && f.key != key;
      f = engine.nextField(answers)
    ) {
      answers = engine.apply(
        answers,
        f.key,
        QuestionnaireAutofill.defaultAnswer(engine, f, answers),
      );
    }
    return answers;
  }

  String? questionKey(IntakeCubit c) => switch (c.state.step) {
    QuestionStep(:final field) => field.key,
    _ => null,
  };
  AnswerValue? saved(String key) => profiles.current!.answers[key];

  /// Answers the current question with a simple valid answer.
  Future<void> answerSample(IntakeCubit c) {
    final field = (c.state.step as QuestionStep).field;
    final engine = engineFor(c.state.gender);
    return c.submit(
      QuestionnaireAutofill.defaultAnswer(engine, field, c.state.answers),
    );
  }

  group('starting', () {
    test('a new user is greeted, then gets the first question', () async {
      final cubit = await build();
      expect(cubit.state.step, isA<GreetingStep>());
      expect(cubit.state.canGoBack, isFalse);
      expect(cubit.state.progress.answered, 0);

      cubit.continueToQuestion();
      expect(questionKey(cubit), 'name');
      expect(cubit.state.reply, isNull);
    });

    test(
      'resumes at the first unanswered question, without a greeting',
      () async {
        final cubit = await build(answers: answeredUntil('country'));
        expect(questionKey(cubit), 'country');
        expect(cubit.state.reply, isNull);
      },
    );

    test('resuming at a chapter start shows its intro first', () async {
      final cubit = await build(answers: answeredUntil('religious_commitment'));
      final step = cubit.state.step as ChapterIntroStep;
      expect(step.chapter.id, 2);
      cubit.continueToQuestion();
      expect(questionKey(cubit), 'religious_commitment');
    });

    test('without a profile there is nothing to ask', () async {
      final repo = LocalProfileRepository(await mockPrefs());
      addTearDown(repo.dispose);
      final cubit = IntakeCubit(
        profiles: repo,
        engineFor: engineFor,
        deviceCountryIso: 'SA',
      );
      addTearDown(cubit.close);
      expect(cubit.state.step, isA<DoneStep>());
    });
  });

  group('answering', () {
    test('every answer is saved straight away', () async {
      final cubit = await build()
        ..continueToQuestion();
      await cubit.submitTyped('  Sara ');
      expect(saved('name'), const TextAnswer('Sara'));
      expect(questionKey(cubit), 'age');
      expect(cubit.state.name, 'Sara');
      expect(cubit.state.progress.answered, 1);
    });

    test('numbers: errors are shown and nothing is saved', () async {
      final cubit = await build(answers: answeredUntil('age'));
      await cubit.submitTyped('15');
      expect(cubit.state.invalid, InvalidReason.outOfRange);
      await cubit.submitTyped(' ');
      expect(cubit.state.invalid, InvalidReason.empty);
      await cubit.submitTyped('2x');
      expect(cubit.state.invalid, InvalidReason.wrongType);
      expect(saved('age'), isNull);
      expect(questionKey(cubit), 'age');

      cubit.draftChanged();
      expect(cubit.state.invalid, isNull);
    });

    test('numbers can be typed in Arabic digits', () async {
      final cubit = await build(answers: answeredUntil('age'));
      await cubit.submitTyped('٢٩');
      expect(saved('age'), const NumberAnswer(29));
    });

    test('an invalid name is rejected', () async {
      final cubit = await build()
        ..continueToQuestion();
      await cubit.submitTyped('Sara123');
      expect(cubit.state.invalid, InvalidReason.invalidName);
      expect(saved('name'), isNull);
    });

    test('"Never married" skips the children question', () async {
      final cubit = await build(answers: answeredUntil('marital_status'));
      await cubit.choose('never_married');
      expect(questionKey(cubit), 'education');
    });

    test('Skip works on optional questions only', () async {
      final cubit = await build(answers: answeredUntil('height_cm'));
      await cubit.skip();
      expect(saved('height_cm'), const SkippedAnswer());
      expect(questionKey(cubit), 'marital_status');

      await cubit.skip();
      expect(cubit.state.invalid, InvalidReason.notOptional);
      expect(saved('marital_status'), isNull);
    });

    test('multi-select: saved as ids plus own entries', () async {
      final cubit = await build(answers: answeredUntil('languages'));
      await cubit.submit(
        MultiAnswer(['arabic', 'english'], custom: ['Tigrinya']),
      );
      expect(
        saved('languages'),
        MultiAnswer(['arabic', 'english'], custom: ['Tigrinya']),
      );
    });

    test('multi-select: nothing picked is rejected', () async {
      final cubit = await build(answers: answeredUntil('languages'));
      await cubit.submit(MultiAnswer([]));
      expect(cubit.state.invalid, InvalidReason.empty);
    });

    test('a second nationality can be "No" or a country', () async {
      final cubit = await build(answers: answeredUntil('second_nationality'));
      await cubit.submit(const NoneAnswer());
      expect(saved('second_nationality'), const NoneAnswer());
      cubit.back();
      await cubit.submit(CountryAnswer('EG'));
      expect(saved('second_nationality'), CountryAnswer('EG'));
    });

    test('a failed save is reported and the question stays', () async {
      final repo = _FailingProfiles(profileAt(OnboardingStage.needsIntake));
      final cubit = IntakeCubit(
        profiles: repo,
        engineFor: engineFor,
        deviceCountryIso: 'SA',
      )..continueToQuestion();
      addTearDown(cubit.close);
      await cubit.submitTyped('Sara');
      expect(cubit.state.saveFailed, isTrue);
      expect(cubit.state.isSaving, isFalse);
      expect(questionKey(cubit), 'name');
    });

    test('the last answer marks the questionnaire as done', () async {
      final all = QuestionnaireAutofill.answerAll(engineFor(Gender.female));
      final last = engineFor(Gender.female).previousField(null, all)!;
      final cubit = await build(answers: all.remove(last.key));
      expect(questionKey(cubit), last.key);

      await answerSample(cubit);
      expect(cubit.state.step, isA<DoneStep>());
      expect(profiles.current!.progress.intakeDoneAt, now);
    });
  });

  group('Khalty\'s replies', () {
    test('the name gets "nice to meet you", then replies take turns', () async {
      final cubit = await build()
        ..continueToQuestion();
      await cubit.submitTyped('Sara');
      expect(cubit.state.reply, const NameReply());
      await cubit.submitTyped('29');
      expect(cubit.state.reply, const GeneralReply(0));
      await cubit.submit(CountryAnswer('SA'));
      expect(cubit.state.reply, const GeneralReply(1));
    });

    test('a chapter intro replaces the reply', () async {
      final before = answeredUntil('religious_commitment');
      final engine = engineFor(Gender.female);
      final lastOfChapter1 = engine.previousField(
        'religious_commitment',
        before,
      )!;
      final cubit = await build(answers: before.remove(lastOfChapter1.key));
      expect(questionKey(cubit), lastOfChapter1.key);

      await answerSample(cubit);
      expect(cubit.state.step, isA<ChapterIntroStep>());
      cubit.continueToQuestion();
      expect(questionKey(cubit), 'religious_commitment');
      expect(cubit.state.reply, isNull);
    });
  });

  group('suggestions', () {
    test('"Where do you live?" suggests the phone country', () async {
      final cubit = await build(answers: answeredUntil('country'));
      expect(cubit.state.suggestedCountry, 'AE');
    });

    test('nationality suggests the country of residence', () async {
      final cubit = await build(answers: answeredUntil('country'));
      await cubit.submit(CountryAnswer('EG'));
      expect(questionKey(cubit), 'city');
      await cubit.submitTyped('Cairo');
      expect(questionKey(cubit), 'nationality');
      expect(cubit.state.suggestedCountry, 'EG');
    });

    test('coming back suggests the earlier answer', () async {
      final cubit = await build(answers: answeredUntil('city'));
      // The sample answer for "Where do you live?" is Saudi Arabia.
      cubit.back();
      expect(cubit.state.suggestedCountry, 'SA');
    });

    test('a second nationality has no suggestion until answered', () async {
      final cubit = await build(answers: answeredUntil('second_nationality'));
      expect(cubit.state.suggestedCountry, isNull);
    });

    test('partner age starts around the user age', () async {
      final answers = answeredUntil('partner_age'); // age 30, woman
      final cubit = await build(answers: answers)
        ..continueToQuestion(); // past chapter 4's intro
      expect(questionKey(cubit), 'partner_age');
      expect(
        cubit.state.suggestedRange,
        engineFor(Gender.female).suggestedRange('partner_age', answers),
      );
      await cubit.submit(RangeAnswer(28, 36));
      cubit.back();
      expect(cubit.state.suggestedRange, RangeAnswer(28, 36));
    });

    test('other questions have no suggestions', () async {
      final cubit = await build(answers: answeredUntil('age'));
      expect(cubit.state.suggestedCountry, isNull);
      expect(cubit.state.suggestedRange, isNull);
    });
  });

  group('Back', () {
    test('goes to the previous question, keeping answers', () async {
      final cubit = await build(answers: answeredUntil('country'));
      cubit.back();
      expect(questionKey(cubit), 'age');
      expect(cubit.state.answers['age'], isNotNull);
      expect(cubit.state.reply, isNull);
    });

    test(
      'from the first question back to the greeting, then no further',
      () async {
        final cubit = await build()
          ..continueToQuestion();
        cubit.back();
        expect(cubit.state.step, isA<GreetingStep>());
        cubit.back();
        expect(cubit.state.step, isA<GreetingStep>());
      },
    );

    test(
      'from a chapter intro to the previous chapter\'s last question',
      () async {
        final answers = answeredUntil('religious_commitment');
        final cubit = await build(answers: answers);
        expect(cubit.state.step, isA<ChapterIntroStep>());
        cubit.back();
        expect(
          questionKey(cubit),
          engineFor(Gender.female)
              .previousField('religious_commitment', answers)!
              .key,
        );
      },
    );

    test('skips questions that do not apply', () async {
      final cubit = await build(answers: answeredUntil('education'));
      // The sample marital status is "never married": no children question.
      cubit.back();
      expect(questionKey(cubit), 'marital_status');
    });

    test('then moving forward passes the already answered questions', () async {
      final cubit = await build(answers: answeredUntil('country'));
      cubit
        ..back()
        ..back();
      expect(questionKey(cubit), 'name');
      await cubit.submitTyped('Sara');
      expect(questionKey(cubit), 'age');
      await cubit.submitTyped('31');
      expect(questionKey(cubit), 'country');
      expect(saved('age'), const NumberAnswer(31));
    });
  });
}

/// A profile store whose saves always fail.
class _FailingProfiles implements ProfileRepository {
  _FailingProfiles(this.current);

  @override
  final UserProfile? current;

  @override
  Future<void> save(UserProfile profile) async => throw Exception('disk full');

  @override
  Future<void> clear() async {}

  @override
  Stream<UserProfile?> watch() => const Stream.empty();
}
