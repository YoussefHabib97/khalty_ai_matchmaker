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

  @override
  String get welcomeMeet => 'Meet Khalty';

  @override
  String get welcomeTagline => 'Your personal matchmaker 💍';

  @override
  String get welcomeTitle => 'Find your forever, one match at a time';

  @override
  String get welcomeBody =>
      'Chat with Khalty. She learns what matters to you and introduces one thoughtful match at a time.';

  @override
  String get getStarted => 'Get started ♥';

  @override
  String get genderQuestion => 'I am…';

  @override
  String get genderMan => 'A man';

  @override
  String get genderWoman => 'A woman';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get consentText =>
      'I agree that Khalty is present in my conversations to keep them safe and may give me private tips, and that my data is stored securely and never shared without my consent.';

  @override
  String get sendCode => 'Send code';

  @override
  String get errorPickGender => 'Please choose man or woman';

  @override
  String get errorPhoneInvalid => 'Please enter a valid mobile number.';

  @override
  String get errorAgreeFirst => 'Please tick the agreement to continue.';

  @override
  String get errorSendFailed =>
      'Could not send the code. Check the number and try again.';

  @override
  String get errorCodeWrong => 'The code is not correct. Please try again.';

  @override
  String get errorCodeExpired =>
      'This code has expired. Please ask for a new one.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a little and try again.';

  @override
  String codeSentTo(String phone) {
    return 'We sent a 6-digit code by SMS to $phone.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get changeNumber => 'Change number';

  @override
  String testCodeHint(String code) {
    return 'Test code: $code';
  }

  @override
  String get chooseCountry => 'Choose a country';

  @override
  String get countrySearchHint => 'Search countries';

  @override
  String get countriesCommon => 'Common';

  @override
  String get countriesAll => 'All countries';

  @override
  String get countriesNoResults => 'No countries found';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get intakeBegin => 'Let\'s begin';

  @override
  String get intakeContinue => 'Continue';

  @override
  String get intakeSkip => 'Skip';

  @override
  String get intakeWhyThisQuestion => 'Why this question?';

  @override
  String intakeChapterOf(int current, int total) {
    return 'Chapter $current of $total';
  }

  @override
  String intakeQuestionsLeft(int count) {
    return '$count left';
  }

  @override
  String get intakeComingSoon =>
      'This kind of answer is coming in the next update.';

  @override
  String get intakeUseSample => 'Use a sample answer';

  @override
  String get answerRequired => 'Please answer to continue.';

  @override
  String answerTooLong(int max) {
    return 'Please keep it to $max characters or fewer.';
  }

  @override
  String get answerLettersOnly => 'Please use letters only.';

  @override
  String answerNumberBetween(int min, int max) {
    return 'Please enter a number between $min and $max.';
  }

  @override
  String get answerNumberRequired => 'Please type a number.';

  @override
  String get answerInvalid =>
      'This answer can\'t be accepted. Please try again.';

  @override
  String get answerSaveFailed =>
      'Couldn\'t save your answer. Please try again.';
}
