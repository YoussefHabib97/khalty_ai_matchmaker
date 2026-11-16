import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/l10n/cubit/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await SharedPrefs.init();
}

void main() {
  group('LocaleCubit first run', () {
    test('uses Arabic when the device is Arabic', () async {
      await _prefs({});
      final cubit = LocaleCubit(deviceLocale: const Locale('ar', 'SA'));
      expect(cubit.state, const Locale('ar'));
    });

    test('falls back to English for unsupported device languages', () async {
      await _prefs({});
      final cubit = LocaleCubit(deviceLocale: const Locale('fr', 'FR'));
      expect(cubit.state, const Locale('en'));
    });
  });

  test('saved choice wins over the device language', () async {
    await _prefs({kAppLocaleKey: 'en'});
    final cubit = LocaleCubit(deviceLocale: const Locale('ar'));
    expect(cubit.state, const Locale('en'));
  });

  test('setLocale saves and survives a restart', () async {
    await _prefs({});
    final cubit = LocaleCubit(deviceLocale: const Locale('en'));
    await cubit.setLocale(const Locale('ar'));
    expect(cubit.state, const Locale('ar'));
    expect(SharedPrefs.getData(key: kAppLocaleKey), 'ar');

    final restarted = LocaleCubit(deviceLocale: const Locale('en'));
    expect(restarted.state, const Locale('ar'));
  });

  test('ignores unsupported locales', () async {
    await _prefs({});
    final cubit = LocaleCubit(deviceLocale: const Locale('en'));
    await cubit.setLocale(const Locale('de'));
    expect(cubit.state, const Locale('en'));
    expect(SharedPrefs.getData(key: kAppLocaleKey), isNull);
  });
}
