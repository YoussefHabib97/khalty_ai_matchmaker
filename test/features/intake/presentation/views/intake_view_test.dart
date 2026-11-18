import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/device_country.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/intake_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/app.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();

  /// The question text of [key] as the screen shows it.
  String question(
    String key, {
    AppLanguage language = AppLanguage.en,
    Gender gender = Gender.female,
    String? name,
    String? country,
  }) => config
      .field(key)!
      .question
      .resolve(
        language,
        gender,
        vars: {'name': ?name, 'detected': ?country, 'residence': ?country},
      );

  /// The saved answer to [key].
  AnswerValue? saved(String key) =>
      getIt<ProfileRepository>().current!.answers[key];

  /// Opens the app for a signed-in user who has given [answers].
  Future<void> openIntake(
    WidgetTester tester, {
    Answers? answers,
    Gender gender = Gender.female,
    String language = 'en',
  }) async {
    final profile = profileAt(OnboardingStage.needsIntake, gender: gender);
    await pumpApp(tester, {
      ...storedSession(profile.copyWith(answers: answers)),
      LocalSettingsRepository.localeKey: language,
    });
    expect(find.byType(IntakeView), findsOneWidget);
  }

  /// Sample answers to every question before [key].
  Answers answeredUntil(String key) {
    final engine = QuestionnaireEngine(config, Gender.female);
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

  Finder answerField() => find.descendant(
    of: find.byType(IntakeView),
    matching: find.byType(TextField),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('greeting, then the name, then Khalty uses it', (tester) async {
    await openIntake(tester);
    expect(find.textContaining('I\'m Khalty'), findsOneWidget);
    expect(find.text('Chapter 1 of 5'), findsOneWidget);

    await tapAndSettle(tester, find.text('Let\'s begin'));
    expect(find.text(question('name')), findsOneWidget);

    await tester.enterText(answerField(), 'Sara');
    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Nice to meet you, Sara! 🌸'), findsOneWidget);
    expect(find.text(question('age', name: 'Sara')), findsOneWidget);
  });

  testWidgets('a wrong age shows the config message; Arabic digits work', (
    tester,
  ) async {
    await openIntake(tester, answers: answeredUntil('age'));

    await tester.enterText(answerField(), '15');
    await tapAndSettle(tester, find.text('Continue'));
    expect(
      find.text(
        config.field('age')!.invalid!.resolve(AppLanguage.en, Gender.female),
      ),
      findsOneWidget,
    );

    await tester.enterText(answerField(), '٢٩');
    await tapAndSettle(tester, find.text('Continue'));
    expect(saved('age'), const NumberAnswer(29));
  });

  group('countries', () {
    final phoneCountry = deviceCountry();

    testWidgets('"Yes" confirms the phone country', (tester) async {
      await openIntake(tester, answers: answeredUntil('country'));
      expect(
        find.text(
          question('country', country: phoneCountry.name(AppLanguage.en)),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.byKey(const Key('countryYes')));
      expect(saved('country'), CountryAnswer(phoneCountry.iso2));
      expect(find.text(question('city', name: 'Sara')), findsOneWidget);
    });

    testWidgets('"No" opens the list; nationality then suggests it', (
      tester,
    ) async {
      await openIntake(tester, answers: answeredUntil('country'));
      await tapAndSettle(tester, find.byKey(const Key('countryOther')));
      // The list is titled with the question's own wording.
      expect(
        find.text(
          config
              .field('country')!
              .questionPick!
              .resolve(AppLanguage.en, Gender.female),
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'egypt',
      );
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Egypt'));
      expect(saved('country'), CountryAnswer('EG'));

      await tester.enterText(answerField(), 'Cairo');
      await tapAndSettle(tester, find.text('Continue'));
      expect(
        find.text(question('nationality', country: 'Egypt')),
        findsOneWidget,
      );
    });

    testWidgets('no second nationality', (tester) async {
      await openIntake(tester, answers: answeredUntil('second_nationality'));
      await tapAndSettle(tester, find.byKey(const Key('countryNone')));
      expect(saved('second_nationality'), const NoneAnswer());
      expect(find.text(question('languages')), findsOneWidget);
    });
  });

  group('multi-select', () {
    testWidgets('chips plus an answer of your own', (tester) async {
      await openIntake(tester, answers: answeredUntil('languages'));
      await tapAndSettle(tester, find.byKey(const Key('option-arabic')));
      await tapAndSettle(tester, find.byKey(const Key('option-english')));
      await tester.enterText(find.byKey(const Key('multiOwn')), 'Tigrinya');
      await tapAndSettle(tester, find.byKey(const Key('multiOwnAdd')));
      // Typing an option's name picks the option instead (in any language).
      await tester.enterText(find.byKey(const Key('multiOwn')), 'الفرنسية');
      await tapAndSettle(tester, find.byKey(const Key('multiOwnAdd')));
      expect(find.widgetWithText(InputChip, 'Tigrinya'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('answerSubmit')));
      expect(
        saved('languages'),
        MultiAnswer(['arabic', 'english', 'french'], custom: ['Tigrinya']),
      );
    });

    testWidgets('nothing picked shows an error', (tester) async {
      await openIntake(tester, answers: answeredUntil('languages'));
      await tapAndSettle(tester, find.byKey(const Key('answerSubmit')));
      expect(find.text('Please pick at least one.'), findsOneWidget);
    });

    testWidgets('at the limit the other chips are disabled', (tester) async {
      await openIntake(tester, answers: answeredUntil('must_haves'));
      expect(find.text('You can pick up to 3 (3 left)'), findsOneWidget);
      for (final id in ['religious', 'kind', 'family_oriented']) {
        await tapAndSettle(tester, find.byKey(Key('option-$id')));
      }
      expect(find.text('You can pick up to 3 (0 left)'), findsOneWidget);
      FilterChip chip(String id) =>
          tester.widget(find.byKey(Key('option-$id')));
      expect(chip('educated').onSelected, isNull);
      expect(chip('kind').onSelected, isNotNull); // can still be unpicked
    });
  });

  testWidgets('partner age starts around the user age', (tester) async {
    final answers = answeredUntil('partner_age'); // age 30, woman
    final start = QuestionnaireEngine(
      config,
      Gender.female,
    ).suggestedRange('partner_age', answers)!;
    await openIntake(tester, answers: answers);
    await tapAndSettle(tester, find.byKey(const Key('intakeIntroContinue')));

    expect(find.text('${start.min} to ${start.max} years'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('answerSubmit')));
    expect(saved('partner_age'), start);
  });

  testWidgets('tapping an option answers and moves on', (tester) async {
    await openIntake(tester, answers: answeredUntil('marital_status'));
    await tapAndSettle(tester, find.byKey(const Key('option-never_married')));
    // No children question after "Never married".
    expect(find.text(question('education', name: 'Sara')), findsOneWidget);
  });

  testWidgets('Skip on optional questions', (tester) async {
    await openIntake(tester, answers: answeredUntil('height_cm'));
    await tapAndSettle(tester, find.text('Skip'));
    expect(find.text(question('marital_status', name: 'Sara')), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('"Why this question?" explains', (tester) async {
    await openIntake(tester, answers: answeredUntil('age'));
    await tapAndSettle(tester, find.text('Why this question?'));
    expect(
      find.text(
        config.field('age')!.why.resolve(AppLanguage.en, Gender.female),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Back shows the earlier answer again', (tester) async {
    await openIntake(tester, answers: answeredUntil('country'));
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.text(question('age', name: 'Sara')), findsOneWidget);
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
  });

  testWidgets('a chapter starts with Khalty\'s intro', (tester) async {
    await openIntake(tester, answers: answeredUntil('religious_commitment'));
    expect(find.text('Faith'), findsWidgets);
    expect(find.textContaining('a few questions about faith'), findsOneWidget);
    await tapAndSettle(tester, find.text('Continue'));
    expect(
      find.text(question('religious_commitment', name: 'Sara')),
      findsOneWidget,
    );
  });

  testWidgets('Arabic, as a man: right-to-left with the men\'s wording', (
    tester,
  ) async {
    await openIntake(tester, gender: Gender.male, language: 'ar');
    await tapAndSettle(tester, find.text('لنبدأ'));
    final text = question(
      'name',
      language: AppLanguage.ar,
      gender: Gender.male,
    );
    expect(text, contains('يا ابني'));
    expect(find.text(text), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(text))),
      TextDirection.rtl,
    );
  });

  testWidgets('the app bar language button switches language', (tester) async {
    await openIntake(tester, answers: answeredUntil('age'));
    await tapAndSettle(tester, find.byTooltip('Change language'));
    await tapAndSettle(tester, find.text('العربية'));
    expect(
      find.text(question('age', language: AppLanguage.ar, name: 'Sara')),
      findsOneWidget,
    );
  });

  testWidgets('the last answer moves on to the self-introduction', (
    tester,
  ) async {
    final engine = QuestionnaireEngine(config, Gender.female);
    final all = QuestionnaireAutofill.answerAll(engine);
    final last = engine.previousField(null, all)!;
    await openIntake(tester, answers: all.remove(last.key));

    await answerThroughUi(tester);
    expect(find.byType(SelfIntroView), findsOneWidget);
  });

  for (final (gender, language) in [
    (Gender.female, 'en'),
    (Gender.male, 'ar'),
  ]) {
    testWidgets('full run as a ${gender.name} in $language, by tapping only', (
      tester,
    ) async {
      await openIntake(tester, gender: gender, language: language);
      var steps = 0;
      while (find.byType(IntakeView).evaluate().isNotEmpty) {
        await answerThroughUi(tester);
        expect(++steps, lessThan(60), reason: 'stuck on a question');
      }

      expect(find.byType(SelfIntroView), findsOneWidget);
      final profile = getIt<ProfileRepository>().current!;
      final engine = QuestionnaireEngine(config, gender);
      expect(engine.nextField(profile.answers), isNull);
      expect(profile.progress.intakeDoneAt, isNotNull);
    });
  }
}

/// Answers whatever the questionnaire shows, the way a user would, in any
/// language: Continue on intros, a simple answer on questions.
Future<void> answerThroughUi(WidgetTester tester) async {
  final state = tester
      .element(find.byType(IntakeView))
      .read<IntakeCubit>()
      .state;
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> type(String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(IntakeView),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tap(find.byKey(const Key('answerSubmit')));
  }

  switch (state.step) {
    case GreetingStep() || ChapterIntroStep():
      await tap(find.byKey(const Key('intakeIntroContinue')));
    case QuestionStep(:final field):
      final firstOption = field.optionsFor(state.gender).firstOrNull?.id;
      switch (field.input) {
        case InputType.text:
          await type(field.key == 'name' ? 'Sara' : 'Something');
        case InputType.number:
          await type(field.key == 'age' ? '29' : '${field.min}');
        case InputType.choice:
          await tap(find.byKey(Key('option-$firstOption')));
        case InputType.multi:
          await tap(find.byKey(Key('option-$firstOption')));
          await tap(find.byKey(const Key('answerSubmit')));
        case InputType.range:
          await tap(find.byKey(const Key('answerSubmit')));
        case InputType.country:
          await tap(find.byKey(const Key('countryYes')));
        case InputType.countryOptional:
          await tap(find.byKey(const Key('countryNone')));
      }
    case DoneStep():
      await tester.pumpAndSettle();
  }
}
