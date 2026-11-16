import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/theme/cubit/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/prefs.dart';

void main() {
  test('defaults to the system theme', () async {
    final cubit = AppThemeCubit(await mockPrefs());
    expect(cubit.themeMode, ThemeMode.system);
    expect(cubit.getThemeState(), {ThemeState.deviceDefault});
  });

  test('setTheme saves the choice and updates themeMode', () async {
    final prefs = await mockPrefs();
    final cubit = AppThemeCubit(prefs);

    await cubit.setTheme(ThemeState.dark);
    expect(cubit.state, isA<DarkThemeState>());
    expect(cubit.themeMode, ThemeMode.dark);
    expect(prefs.getData(key: kAppThemeKey), kAppThemeDark);

    await cubit.setTheme(ThemeState.light);
    expect(cubit.themeMode, ThemeMode.light);
    expect(cubit.getThemeState(), {ThemeState.light});
  });
}
