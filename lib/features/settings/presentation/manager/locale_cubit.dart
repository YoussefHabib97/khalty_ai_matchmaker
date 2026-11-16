import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';

/// ViewModel for the app language. The saved choice wins; on first run the
/// device language is used when supported (Arabic), otherwise English.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._settings, {Locale? deviceLocale})
    : super(
        _initial(_settings, deviceLocale ?? PlatformDispatcher.instance.locale),
      );

  final SettingsRepository _settings;

  static Locale _initial(SettingsRepository settings, Locale device) {
    final saved = settings.languageCode;
    if (saved != null && _isSupported(saved)) return Locale(saved);
    if (_isSupported(device.languageCode)) return Locale(device.languageCode);
    return const Locale('en');
  }

  static bool _isSupported(String languageCode) => AppLocalizations
      .supportedLocales
      .any((l) => l.languageCode == languageCode);

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    await _settings.saveLanguageCode(locale.languageCode);
    emit(Locale(locale.languageCode));
  }
}
