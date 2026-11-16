// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Khalty';

  @override
  String get languageLabel => 'Language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String welcomeGreeting(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Welcome, my son',
      'female': 'Welcome, my daughter',
      'other': 'Welcome',
    });
    return '$_temp0';
  }

  @override
  String get tabKhalty => 'Khalty';

  @override
  String get tabMatches => 'Matches';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMe => 'Me';

  @override
  String get signUpTitle => 'Sign up';

  @override
  String get verifyCodeTitle => 'Verify your number';

  @override
  String get intakeTitle => 'Getting to know you';

  @override
  String get selfIntroTitle => 'In your own words';

  @override
  String get reviewTitle => 'What I understood';

  @override
  String get placeholderComingSoon => 'This screen is coming soon.';
}
