import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';
import 'package:material_ui/material_ui.dart';

/// ViewModel for the app theme. Its state is the user's preference.
class AppThemeCubit extends Cubit<ThemePreference> {
  AppThemeCubit(this._settings) : super(_settings.theme);

  final SettingsRepository _settings;

  /// The mode `MaterialApp` should use.
  ThemeMode get themeMode => switch (state) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.deviceDefault => ThemeMode.system,
  };

  Future<void> setTheme(ThemePreference theme) async {
    await _settings.saveTheme(theme);
    emit(theme);
  }
}
