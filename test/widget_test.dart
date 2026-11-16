import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_selector.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/theme_switcher_widget.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(375, 812) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // Real async work (asset loading) must run outside the fake test clock.
  await tester.runAsync(setupServiceLocator);
  addTearDown(getIt.reset);

  await tester.pumpWidget(const ApplicationRoot());
  await tester.pumpAndSettle();
}

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(OnboardingView)));

void main() {
  testWidgets('App starts on the onboarding view in English, LTR', (
    tester,
  ) async {
    await _pumpApp(tester, {LocalSettingsRepository.localeKey: 'en'});

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.byType(ThemeSwitcherWidget), findsOneWidget);
    expect(find.text('Khalty'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);
  });

  testWidgets('Saved Arabic starts the app right-to-left', (tester) async {
    await _pumpApp(tester, {LocalSettingsRepository.localeKey: 'ar'});

    expect(find.text('خالتي'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);
  });

  testWidgets('Switching to Arabic flips the layout and is saved', (
    tester,
  ) async {
    await _pumpApp(tester, {LocalSettingsRepository.localeKey: 'en'});

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
}
