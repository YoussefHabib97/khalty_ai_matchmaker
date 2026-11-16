import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';

/// In-memory [SettingsRepository] for ViewModel tests: no storage involved.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.theme = ThemePreference.deviceDefault,
    this.languageCode,
  });

  @override
  ThemePreference theme;

  @override
  String? languageCode;

  @override
  Future<void> saveTheme(ThemePreference theme) async => this.theme = theme;

  @override
  Future<void> saveLanguageCode(String code) async => languageCode = code;
}
