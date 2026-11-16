import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/app/navigation/main_shell.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/intake_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/khalty_chat/presentation/views/khalty_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/welcome_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_selector.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/theme_switcher_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/session.dart';

Future<void> _pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({
    LocalSettingsRepository.localeKey: 'en',
    ...prefs,
  });
  tester.view.physicalSize = const Size(375, 812) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // Real async work (asset loading) must run outside the fake test clock.
  await tester.runAsync(setupServiceLocator);
  addTearDown(getIt.reset);

  await tester.pumpWidget(ApplicationRoot(router: getIt(), session: getIt()));
  await tester.pumpAndSettle();
}

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(WelcomeView)));

void main() {
  group('language', () {
    testWidgets('a signed-out user starts on Welcome, in English, LTR', (
      tester,
    ) async {
      await _pumpApp(tester, {});

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(find.byType(ThemeSwitcherWidget), findsOneWidget);
      expect(find.text('Khalty'), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('saved Arabic starts the app right-to-left', (tester) async {
      await _pumpApp(tester, {LocalSettingsRepository.localeKey: 'ar'});

      expect(find.text('خالتي'), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('switching to Arabic flips the layout and is saved', (
      tester,
    ) async {
      await _pumpApp(tester, {});

      // Open the dropdown, then pick Arabic from the menu.
      await tester.tap(find.byType(LanguageSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية').last);
      await tester.pumpAndSettle();

      expect(_direction(tester), TextDirection.rtl);
      expect(find.text('أهلًا وسهلًا'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocalSettingsRepository.localeKey), 'ar');
    });
  });

  group('navigation', () {
    testWidgets('each stored stage opens on its own screen', (tester) async {
      await _pumpApp(tester, storedSessionAt(OnboardingStage.needsSelfIntro));
      expect(find.byType(SelfIntroView), findsOneWidget);
    });

    testWidgets('a finished user gets the tabs and can switch between them', (
      tester,
    ) async {
      await _pumpApp(tester, storedSessionAt(OnboardingStage.complete));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(KhaltyTabView), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Me'));
      await tester.pumpAndSettle();
      expect(find.byType(MeView), findsOneWidget);
    });

    testWidgets('signing in moves from Welcome to the questionnaire', (
      tester,
    ) async {
      await _pumpApp(tester, {});
      expect(find.byType(WelcomeView), findsOneWidget);

      // Debug panel: fake SMS sign-in (simulated network delays).
      await tester.tap(find.text('Sign in (woman)'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(IntakeView), findsOneWidget);
    });
  });
}
