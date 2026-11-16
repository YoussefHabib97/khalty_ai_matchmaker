import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';

/// Holds the app language. The saved choice wins; on first run the device
/// language is used when supported (Arabic), otherwise English.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({Locale? deviceLocale})
    : super(_initial(deviceLocale ?? PlatformDispatcher.instance.locale));

  static Locale _initial(Locale device) {
    final saved = SharedPrefs.getData(key: kAppLocaleKey);
    if (saved is String && _isSupported(saved)) return Locale(saved);
    if (_isSupported(device.languageCode)) return Locale(device.languageCode);
    return const Locale('en');
  }

  static bool _isSupported(String languageCode) => AppLocalizations
      .supportedLocales
      .any((l) => l.languageCode == languageCode);

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    await SharedPrefs.setData(key: kAppLocaleKey, value: locale.languageCode);
    emit(Locale(locale.languageCode));
  }
}
