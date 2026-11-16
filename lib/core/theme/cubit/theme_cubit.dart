import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

part 'theme_state.dart';

class AppThemeCubit extends Cubit<AppThemeState> {
  AppThemeCubit(this._prefs) : super(AppThemeInitialState());

  final SharedPrefs _prefs;

  /// The mode `MaterialApp` should use, read from the saved choice.
  ThemeMode get themeMode => switch (_prefs.getData(key: kAppThemeKey)) {
    kAppThemeLight => ThemeMode.light,
    kAppThemeDark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Set<ThemeState> getThemeState() => switch (themeMode) {
    ThemeMode.light => {ThemeState.light},
    ThemeMode.dark => {ThemeState.dark},
    ThemeMode.system => {ThemeState.deviceDefault},
  };

  Future<void> setTheme(ThemeState state) async {
    switch (state) {
      case ThemeState.light:
        await _prefs.setData(key: kAppThemeKey, value: kAppThemeLight);
        emit(LightThemeState());
      case ThemeState.dark:
        await _prefs.setData(key: kAppThemeKey, value: kAppThemeDark);
        emit(DarkThemeState());
      case ThemeState.deviceDefault:
        await _prefs.setData(key: kAppThemeKey, value: kAppThemeDeviceDefault);
        emit(DeviceDefaultThemeState());
    }
  }
}
