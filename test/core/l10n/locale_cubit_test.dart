import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/l10n/cubit/locale_cubit.dart';

import '../../helpers/prefs.dart';

void main() {
  group('LocaleCubit first run', () {
    test('uses Arabic when the device is Arabic', () async {
      final cubit = LocaleCubit(
        await mockPrefs(),
        deviceLocale: const Locale('ar', 'SA'),
      );
      expect(cubit.state, const Locale('ar'));
    });

    test('falls back to English for unsupported device languages', () async {
      final cubit = LocaleCubit(
        await mockPrefs(),
        deviceLocale: const Locale('fr', 'FR'),
      );
      expect(cubit.state, const Locale('en'));
    });
  });

  test('saved choice wins over the device language', () async {
    final cubit = LocaleCubit(
      await mockPrefs({kAppLocaleKey: 'en'}),
      deviceLocale: const Locale('ar'),
    );
    expect(cubit.state, const Locale('en'));
  });

  test('setLocale saves and survives a restart', () async {
    final prefs = await mockPrefs();
    final cubit = LocaleCubit(prefs, deviceLocale: const Locale('en'));
    await cubit.setLocale(const Locale('ar'));
    expect(cubit.state, const Locale('ar'));
    expect(prefs.getData(key: kAppLocaleKey), 'ar');

    final restarted = LocaleCubit(prefs, deviceLocale: const Locale('en'));
    expect(restarted.state, const Locale('ar'));
  });

  test('ignores unsupported locales', () async {
    final prefs = await mockPrefs();
    final cubit = LocaleCubit(prefs, deviceLocale: const Locale('en'));
    await cubit.setLocale(const Locale('de'));
    expect(cubit.state, const Locale('en'));
    expect(prefs.getData(key: kAppLocaleKey), isNull);
  });
}
