import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';

/// Device-level app settings. Reads are synchronous because settings are
/// loaded before the app starts.
abstract interface class SettingsRepository {
  /// The saved theme, or [ThemePreference.deviceDefault] if never chosen.
  ThemePreference get theme;
  Future<void> saveTheme(ThemePreference theme);

  /// The saved app language code (e.g. `ar`), or null if never chosen.
  String? get languageCode;
  Future<void> saveLanguageCode(String code);
}
