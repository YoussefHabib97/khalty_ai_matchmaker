import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/fake_settings_repository.dart';

void main() {
  test('starts from the saved preference', () {
    expect(AppThemeCubit(FakeSettingsRepository()).themeMode, ThemeMode.system);
    final dark = AppThemeCubit(
      FakeSettingsRepository(theme: ThemePreference.dark),
    );
    expect(dark.state, ThemePreference.dark);
    expect(dark.themeMode, ThemeMode.dark);
  });

  test('setTheme saves through the repository and updates themeMode', () async {
    final settings = FakeSettingsRepository();
    final cubit = AppThemeCubit(settings);

    await cubit.setTheme(ThemePreference.light);
    expect(cubit.state, ThemePreference.light);
    expect(cubit.themeMode, ThemeMode.light);
    expect(settings.theme, ThemePreference.light);
  });
}
