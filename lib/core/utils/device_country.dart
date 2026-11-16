import 'dart:ui' show PlatformDispatcher;

import 'package:khalty_ai_matchmaker/core/constants/countries.dart';

/// Where users are assumed to be when the phone doesn't say.
const kFallbackCountryIso = 'SA';

/// The country from the phone's region settings (never from a dial code),
/// falling back to Saudi Arabia.
Country deviceCountry() {
  for (final locale in [
    PlatformDispatcher.instance.locale,
    ...PlatformDispatcher.instance.locales,
  ]) {
    final code = locale.countryCode;
    if (code != null) {
      final country = countryByIso(code);
      if (country != null) return country;
    }
  }
  return countryByIso(kFallbackCountryIso)!;
}
