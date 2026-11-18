import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/review_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/khalty_chat/presentation/views/khalty_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/app.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();
  const intro =
      'I am a teacher in Riyadh. I love reading, cooking for my family and '
      'long walks by the sea. I hope to build a calm and faithful home.';

  Future<void> openSelfIntro(
    WidgetTester tester, {
    Gender gender = Gender.female,
    String language = 'en',
  }) async {
    await pumpApp(tester, {
      ...storedSession(
        profileAt(OnboardingStage.needsSelfIntro, gender: gender),
      ),
      LocalSettingsRepository.localeKey: language,
    });
    expect(find.byType(SelfIntroView), findsOneWidget);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Scrolls the review until [finder] is on screen.
  Future<void> reveal(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ReviewView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  /// Sends [text] and waits for the fake AI (2 s).
  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('selfIntroField')), text);
    await tester.pump();
    await tester.tap(find.byKey(const Key('selfIntroSend')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('Send is off until something is typed', (tester) async {
    await openSelfIntro(tester);
    expect(
      find.text(
        config.script.selfIntro.resolve(
          AppLanguage.en,
          Gender.female,
          vars: {'name': 'Sara'},
        ),
      ),
      findsOneWidget,
    );
    FilledButton sendButton() =>
        tester.widget(find.byKey(const Key('selfIntroSend')));
    expect(sendButton().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('selfIntroField')), 'Hi');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('introduce yourself, review, "That\'s me", then the tabs', (
    tester,
  ) async {
    await openSelfIntro(tester);
    await tester.enterText(
      find.byKey(const Key('selfIntroField')),
      '$intro My number is 0501234567. I enjoy shisha at weekends.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('selfIntroSend')));
    await tester.pump();
    // Khalty is putting everything together.
    expect(
      find.text(
        config.script.analysing.resolve(
          AppLanguage.en,
          Gender.female,
          vars: {'name': 'Sara'},
        ),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewView), findsOneWidget);
    expect(find.textContaining('I loved reading'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('reviewPleaseCheck')));
    expect(find.textContaining('I am a teacher in Riyadh'), findsOneWidget);
    expect(find.textContaining('0501234567'), findsNothing);

    await tap(tester, find.byKey(const Key('reviewConfirm')));
    expect(find.byType(KhaltyTabView), findsOneWidget);
  });

  testWidgets('a thin introduction: Khalty asks once, the text stays', (
    tester,
  ) async {
    await openSelfIntro(tester);
    await send(tester, 'hello');
    expect(find.byType(SelfIntroView), findsOneWidget);
    expect(
      find.textContaining('Could you tell me a little more'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'hello'), findsOneWidget);

    await send(tester, 'hello, I am Sara');
    expect(find.byType(ReviewView), findsOneWidget);
  });

  testWidgets('"Not now" still reaches the review, without a bio', (
    tester,
  ) async {
    await openSelfIntro(tester);
    await tester.tap(find.byKey(const Key('selfIntroSkip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewView), findsOneWidget);
    final noBio = find.text(
      'You can add an "About me" later from your profile.',
    );
    await reveal(tester, noBio);
    expect(noBio, findsOneWidget);
    expect(find.byKey(const Key('reviewPleaseCheck')), findsNothing);
  });

  testWidgets('Edit → rewrite goes back with the earlier text', (tester) async {
    await openSelfIntro(tester);
    await send(tester, intro);
    await tap(tester, find.byKey(const Key('reviewEdit')));
    await tap(tester, find.byKey(const Key('reviewRewrite')));

    expect(find.byType(SelfIntroView), findsOneWidget);
    expect(find.widgetWithText(TextField, intro), findsOneWidget);
    expect(getIt<ProfileRepository>().current!.analysis, isNull);
  });

  testWidgets('Arabic, as a man; switching language notes the original', (
    tester,
  ) async {
    await openSelfIntro(tester, gender: Gender.male, language: 'ar');
    final invite = config.script.selfIntro.resolve(
      AppLanguage.ar,
      Gender.male,
      vars: {'name': 'Sara'},
    );
    expect(invite, contains('حدّثني'));
    expect(find.text(invite), findsOneWidget);

    await send(tester, intro);
    expect(find.byType(ReviewView), findsOneWidget);
    expect(find.textContaining('يبحث عن زوجة'), findsOneWidget);
    expect(find.text('مكتوب بالعربية'), findsNothing);

    await tap(tester, find.byTooltip('تغيير اللغة'));
    await tap(tester, find.text('English'));
    expect(find.text('Written in Arabic'), findsOneWidget);
  });
}
