import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/prefs.dart';

void main() {
  test('defaults: device theme and no saved language', () async {
    final repo = LocalSettingsRepository(await mockPrefs());
    expect(repo.theme, ThemePreference.deviceDefault);
    expect(repo.languageCode, isNull);
  });

  test('saves theme and language by name, surviving a restart', () async {
    final repo = LocalSettingsRepository(await mockPrefs());
    await repo.saveTheme(ThemePreference.dark);
    await repo.saveLanguageCode('ar');

    final restarted = LocalSettingsRepository(
      SharedPrefs(await SharedPreferences.getInstance()),
    );
    expect(restarted.theme, ThemePreference.dark);
    expect(restarted.languageCode, 'ar');
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString(LocalSettingsRepository.themeKey), 'dark');
  });

  test('reads values stored by earlier builds', () async {
    final repo = LocalSettingsRepository(
      await mockPrefs({
        LocalSettingsRepository.themeKey: 'light',
        LocalSettingsRepository.localeKey: 'en',
      }),
    );
    expect(repo.theme, ThemePreference.light);
    expect(repo.languageCode, 'en');
  });

  test('an unknown stored theme falls back to device default', () async {
    final repo = LocalSettingsRepository(
      await mockPrefs({LocalSettingsRepository.themeKey: 'purple'}),
    );
    expect(repo.theme, ThemePreference.deviceDefault);
  });
}
