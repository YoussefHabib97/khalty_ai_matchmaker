// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'خالتي';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get themeLabel => 'المظهر';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String welcomeGreeting(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'أهلًا بك يا ابني',
      'female': 'أهلًا بكِ يا بنتي',
      'other': 'أهلًا وسهلًا',
    });
    return '$_temp0';
  }
}
