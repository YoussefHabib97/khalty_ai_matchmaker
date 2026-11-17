import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the whole app on a phone-sized screen with [prefs] as the stored
/// data (English unless [prefs] says otherwise).
Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
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
