import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/app_dependencies.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/language_toggle.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/theme_switcher_widget.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(375, 812) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final dependencies = await AppDependencies.create();
  await tester.pumpWidget(ApplicationRoot(dependencies: dependencies));
  await tester.pumpAndSettle();
}

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(OnboardingView)));

void main() {
  testWidgets('App starts on the onboarding view in English, LTR', (
    tester,
  ) async {
    await _pumpApp(tester, {kAppLocaleKey: 'en'});

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.byType(ThemeSwitcherWidget), findsOneWidget);
    expect(find.text('Khalty'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);
  });

  testWidgets('Saved Arabic starts the app right-to-left', (tester) async {
    await _pumpApp(tester, {kAppLocaleKey: 'ar'});

    expect(find.text('خالتي'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);
  });

  testWidgets('Switching to Arabic flips the layout and is saved', (
    tester,
  ) async {
    await _pumpApp(tester, {kAppLocaleKey: 'en'});

    await tester.tap(
      find.descendant(
        of: find.byType(LanguageToggle),
        matching: find.text('العربية'),
      ),
    );
    await tester.pumpAndSettle();

    expect(_direction(tester), TextDirection.rtl);
    expect(find.text('أهلًا وسهلًا'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAppLocaleKey), 'ar');
  });
}
