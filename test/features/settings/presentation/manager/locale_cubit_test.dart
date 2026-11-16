import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';

import '../../../../helpers/fake_settings_repository.dart';

void main() {
  group('LocaleCubit first run', () {
    test('uses Arabic when the device is Arabic', () {
      final cubit = LocaleCubit(
        FakeSettingsRepository(),
        deviceLocale: const Locale('ar', 'SA'),
      );
      expect(cubit.state, const Locale('ar'));
    });

    test('falls back to English for unsupported device languages', () {
      final cubit = LocaleCubit(
        FakeSettingsRepository(),
        deviceLocale: const Locale('fr', 'FR'),
      );
      expect(cubit.state, const Locale('en'));
    });
  });

  test('saved choice wins over the device language', () {
    final cubit = LocaleCubit(
      FakeSettingsRepository(languageCode: 'en'),
      deviceLocale: const Locale('ar'),
    );
    expect(cubit.state, const Locale('en'));
  });

  test(
    'setLocale saves through the repository and survives a restart',
    () async {
      final settings = FakeSettingsRepository();
      final cubit = LocaleCubit(settings, deviceLocale: const Locale('en'));
      await cubit.setLocale(const Locale('ar'));
      expect(cubit.state, const Locale('ar'));
      expect(settings.languageCode, 'ar');

      final restarted = LocaleCubit(settings, deviceLocale: const Locale('en'));
      expect(restarted.state, const Locale('ar'));
    },
  );

  test('ignores unsupported locales', () async {
    final settings = FakeSettingsRepository();
    final cubit = LocaleCubit(settings, deviceLocale: const Locale('en'));
    await cubit.setLocale(const Locale('de'));
    expect(cubit.state, const Locale('en'));
    expect(settings.languageCode, isNull);
  });
}
