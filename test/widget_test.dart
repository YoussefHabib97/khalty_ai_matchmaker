import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/navigation/main_shell.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/sign_up_view.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/verify_code_view.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/phone_number_field.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/intake_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/khalty_chat/presentation/views/khalty_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/welcome_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app.dart';
import 'helpers/session.dart';

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(WelcomeView)));

void main() {
  group('language', () {
    testWidgets('a signed-out user starts on Welcome, in English, LTR', (
      tester,
    ) async {
      await pumpApp(tester, {});

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(find.text('Meet Khalty'), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('saved Arabic starts the app right-to-left', (tester) async {
      await pumpApp(tester, {LocalSettingsRepository.localeKey: 'ar'});

      expect(find.text('تعرّف على خالتي'), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('switching to Arabic flips the layout and is saved', (
      tester,
    ) async {
      await pumpApp(tester, {});

      // Open the dropdown, then pick Arabic from the menu.
      await tester.tap(find.byType(LanguageSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية').last);
      await tester.pumpAndSettle();

      expect(_direction(tester), TextDirection.rtl);
      expect(find.text('تعرّف على خالتي'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocalSettingsRepository.localeKey), 'ar');
    });
  });

  group('navigation', () {
    testWidgets('each stored stage opens on its own screen', (tester) async {
      await pumpApp(tester, storedSessionAt(OnboardingStage.needsSelfIntro));
      expect(find.byType(SelfIntroView), findsOneWidget);
    });

    testWidgets('a finished user gets the tabs and can switch between them', (
      tester,
    ) async {
      await pumpApp(tester, storedSessionAt(OnboardingStage.complete));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(KhaltyTabView), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Me'));
      await tester.pumpAndSettle();
      expect(find.byType(MeView), findsOneWidget);
    });

    testWidgets('no debug shortcuts are left on any screen', (tester) async {
      await pumpApp(tester, {});
      expect(find.byType(WelcomeView), findsOneWidget);
      expect(find.textContaining('DEBUG'), findsNothing);
      expect(find.text('Sign in (woman)'), findsNothing);
    });
  });

  group('sign-up', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await pumpApp(tester, {});
      await tester.tap(find.text('Get started ♥'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpView), findsOneWidget);
    }

    Finder phoneField() => find.descendant(
      of: find.byType(PhoneNumberField),
      matching: find.byType(TextField),
    );

    testWidgets('the country picker changes the dialling code', (tester) async {
      await openSignUp(tester);
      await tester.tap(find.byKey(const Key('countryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'مصر',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Egypt'));
      await tester.pumpAndSettle();

      expect(find.textContaining('+20'), findsOneWidget);
    });

    testWidgets('errors show until the form is complete', (tester) async {
      await openSignUp(tester);
      await tester.tap(find.text('Send code'));
      await tester.pump();
      expect(find.text('Please choose man or woman'), findsOneWidget);
    });

    testWidgets('full flow: sign up, enter the code, reach the questionnaire', (
      tester,
    ) async {
      await openSignUp(tester);

      await tester.tap(find.text('A woman'));
      await tester.enterText(phoneField(), '0501234567');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Send code'));
      await tester.pump(const Duration(seconds: 1)); // simulated SMS delay
      await tester.pumpAndSettle();
      expect(find.byType(VerifyCodeView), findsOneWidget);
      expect(find.text('Test code: 123456'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(VerifyCodeView),
          matching: find.byType(TextField),
        ),
        '123456',
      );
      await tester.pump(const Duration(seconds: 1)); // simulated verify delay
      await tester.pumpAndSettle();

      expect(find.byType(IntakeView), findsOneWidget);
    });
  });
}
