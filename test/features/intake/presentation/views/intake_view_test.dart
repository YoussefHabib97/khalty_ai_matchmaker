import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/intake_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
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
  }) => config
      .field(key)!
      .question
      .resolve(language, gender, vars: {'name': ?name});

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
    expect(find.text(question('country', name: 'Sara')), findsOneWidget);
  });

  testWidgets('inputs coming in step 9 can use a sample answer', (
    tester,
  ) async {
    await openIntake(tester, answers: answeredUntil('country'));
    await tapAndSettle(tester, find.text('Use a sample answer'));
    expect(find.text(question('city', name: 'Sara')), findsOneWidget);
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

    await tapAndSettle(tester, find.text('Use a sample answer'));
    expect(find.byType(SelfIntroView), findsOneWidget);
  });
}
