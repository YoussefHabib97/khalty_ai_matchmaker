import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';

/// Settings stored on the device with [SharedPrefs].
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._prefs);

  static const themeKey = 'theme';
  static const localeKey = 'app.locale';

  final SharedPrefs _prefs;

  @override
  ThemePreference get theme =>
      ThemePreference.fromName(_prefs.getData(key: themeKey));

  @override
  Future<void> saveTheme(ThemePreference theme) =>
      _prefs.setData(key: themeKey, value: theme.name);

  @override
  String? get languageCode {
    final code = _prefs.getData(key: localeKey);
    return code is String ? code : null;
  }

  @override
  Future<void> saveLanguageCode(String code) =>
      _prefs.setData(key: localeKey, value: code);
}
