import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/navigation/main_shell.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/welcome_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/silhouette.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/views/settings_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/app.dart';
import '../../../../helpers/session.dart';

void main() {
  Future<void> openMe(WidgetTester tester, {String language = 'en'}) async {
    await pumpApp(tester, {
      ...storedSessionAt(OnboardingStage.complete),
      LocalSettingsRepository.localeKey: language,
    });
    await tester.tap(find.byIcon(Icons.person_outline).first);
    await tester.pumpAndSettle();
    expect(find.byType(MeView), findsOneWidget);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the Me tab: silhouette, name, details and "knows you"', (
    tester,
  ) async {
    await openMe(tester);
    expect(find.byType(Silhouette), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('30 years · Something, Saudi Arabia'), findsOneWidget);
    expect(find.text('Khalty knows you 90%'), findsOneWidget);
    expect(
      find.text('You can add a photo whenever you are ready.'),
      findsOneWidget,
    );
    expect(find.text('Bio'), findsOneWidget); // the sample about-me
  });

  testWidgets('Settings opens over the tabs and Back returns', (tester) async {
    await openMe(tester);
    await tap(tester, find.byKey(const Key('openSettings')));
    expect(find.byType(SettingsView), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.textContaining(testUser.phoneE164), findsOneWidget);

    await tap(tester, find.byType(BackButton));
    expect(find.byType(MeView), findsOneWidget);
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('the theme choice is saved', (tester) async {
    await openMe(tester);
    await tap(tester, find.byKey(const Key('openSettings')));
    await tap(tester, find.text('Dark'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocalSettingsRepository.themeKey), 'dark');
    expect(
      Theme.of(tester.element(find.byType(SettingsView))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('sign out asks first, then returns to Welcome', (tester) async {
    await openMe(tester);
    await tap(tester, find.byKey(const Key('openSettings')));

    await tap(tester, find.byKey(const Key('signOut')));
    expect(find.text('Sign out?'), findsOneWidget);
    await tap(tester, find.text('Cancel'));
    expect(find.byType(SettingsView), findsOneWidget);

    await tap(tester, find.byKey(const Key('signOut')));
    await tap(tester, find.byKey(const Key('confirmSignOut')));
    expect(find.byType(WelcomeView), findsOneWidget);
  });

  testWidgets('in Arabic, right-to-left', (tester) async {
    await openMe(tester, language: 'ar');
    expect(find.text('خالتي تعرفك بنسبة 90%'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MeView))),
      TextDirection.rtl,
    );
  });
}
