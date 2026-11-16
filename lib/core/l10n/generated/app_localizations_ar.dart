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

  @override
  String get tabKhalty => 'خالتي';

  @override
  String get tabMatches => 'الترشيحات';

  @override
  String get tabChats => 'المحادثات';

  @override
  String get tabMe => 'حسابي';

  @override
  String get signUpTitle => 'التسجيل';

  @override
  String get verifyCodeTitle => 'تأكيد رقمك';

  @override
  String get intakeTitle => 'لنتعارف';

  @override
  String get selfIntroTitle => 'بكلماتك';

  @override
  String get reviewTitle => 'ما فهمته عنك';

  @override
  String get placeholderComingSoon => 'هذه الشاشة قادمة قريبًا.';
}
