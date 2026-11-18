import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the app bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'Khalty'**
  String get appTitle;

  /// Label for the language selector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Label for the light/dark theme selector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Name of the English language, always written in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the Arabic language, always written in Arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Khalty's greeting. 'gender' is the user's gender (male/female); 'other' is used before the user has chosen.
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male{Welcome, my son} female{Welcome, my daughter} other{Welcome}}'**
  String welcomeGreeting(String gender);

  /// Bottom navigation: Khalty's chat and status tab.
  ///
  /// In en, this message translates to:
  /// **'Khalty'**
  String get tabKhalty;

  /// Bottom navigation: suggested matches tab.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get tabMatches;

  /// Bottom navigation: introduction chats tab.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// Bottom navigation: the user's own profile and settings tab.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// Title of the sign-up screen (gender, phone, consent).
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpTitle;

  /// Title of the screen where the SMS code is entered.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyCodeTitle;

  /// Title of the questionnaire screens.
  ///
  /// In en, this message translates to:
  /// **'Getting to know you'**
  String get intakeTitle;

  /// Title of the self-introduction screen.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get selfIntroTitle;

  /// Title of the screen with Khalty's summary of the user.
  ///
  /// In en, this message translates to:
  /// **'What I understood'**
  String get reviewTitle;

  /// Temporary text on screens that are not built yet.
  ///
  /// In en, this message translates to:
  /// **'This screen is coming soon.'**
  String get placeholderComingSoon;

  /// Welcome screen heading (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Meet Khalty'**
  String get welcomeMeet;

  /// Welcome screen tagline (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Your personal matchmaker 💍'**
  String get welcomeTagline;

  /// Welcome screen title (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Find your forever, one match at a time'**
  String get welcomeTitle;

  /// Welcome screen description (old app text, without 'or talk' since voice comes later).
  ///
  /// In en, this message translates to:
  /// **'Chat with Khalty. She learns what matters to you and introduces one thoughtful match at a time.'**
  String get welcomeBody;

  /// Welcome screen button that opens sign-up.
  ///
  /// In en, this message translates to:
  /// **'Get started ♥'**
  String get getStarted;

  /// Sign-up: label above the man/woman choice. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'I am…'**
  String get genderQuestion;

  /// Sign-up gender choice.
  ///
  /// In en, this message translates to:
  /// **'A man'**
  String get genderMan;

  /// Sign-up gender choice.
  ///
  /// In en, this message translates to:
  /// **'A woman'**
  String get genderWoman;

  /// Sign-up: phone number field label. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// Sign-up consent checkbox (from the old app). Changing the meaning requires bumping Consent.currentVersion.
  ///
  /// In en, this message translates to:
  /// **'I agree that Khalty is present in my conversations to keep them safe and may give me private tips, and that my data is stored securely and never shared without my consent.'**
  String get consentText;

  /// Sign-up button that sends the SMS code. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Sign-up error (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Please choose man or woman'**
  String get errorPickGender;

  /// Sign-up error. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number.'**
  String get errorPhoneInvalid;

  /// Sign-up error (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Please tick the agreement to continue.'**
  String get errorAgreeFirst;

  /// Sign-up error when the SMS or network fails (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Check the number and try again.'**
  String get errorSendFailed;

  /// Code screen error (from the old app).
  ///
  /// In en, this message translates to:
  /// **'The code is not correct. Please try again.'**
  String get errorCodeWrong;

  /// Code screen error. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Please ask for a new one.'**
  String get errorCodeExpired;

  /// Code screen error. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a little and try again.'**
  String get errorTooManyAttempts;

  /// Code screen explanation (from the old app).
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code by SMS to {phone}.'**
  String codeSentTo(String phone);

  /// Code screen: code field label. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// Code screen button (from the old app).
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// Code screen: link to send a new code. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Code screen: countdown before a new code can be sent, e.g. 0:42. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendIn(String time);

  /// Code screen: go back and edit the phone number. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// Debug builds only: the fake SMS code.
  ///
  /// In en, this message translates to:
  /// **'Test code: {code}'**
  String testCodeHint(String code);

  /// Country picker title. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Choose a country'**
  String get chooseCountry;

  /// Country picker search field hint. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get countrySearchHint;

  /// Country picker: frequently used countries section. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get countriesCommon;

  /// Country picker: all countries section. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get countriesAll;

  /// Country picker: nothing matches the search. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get countriesNoResults;

  /// Tooltip of the language icon button in app bars. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// Questionnaire: button under Khalty's greeting. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Let\'s begin'**
  String get intakeBegin;

  /// Questionnaire: next question / after a chapter intro. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get intakeContinue;

  /// Questionnaire: skip an optional question. Arabic uses a gender-neutral 'I'd rather not answer'. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get intakeSkip;

  /// Questionnaire: link that explains why Khalty asks. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Why this question?'**
  String get intakeWhyThisQuestion;

  /// Questionnaire: which chapter the user is in. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String intakeChapterOf(int current, int total);

  /// Questionnaire progress: questions still to answer. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String intakeQuestionsLeft(int count);

  /// Answer error: nothing typed. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please answer to continue.'**
  String get answerRequired;

  /// Answer error: typed text too long. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please keep it to {max} characters or fewer.'**
  String answerTooLong(int max);

  /// Answer error: a name with digits or symbols. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please use letters only.'**
  String get answerLettersOnly;

  /// Answer error: number out of range. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between {min} and {max}.'**
  String answerNumberBetween(int min, int max);

  /// Answer error: not a number. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please type a number.'**
  String get answerNumberRequired;

  /// Answer error: any other problem. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'This answer can\'t be accepted. Please try again.'**
  String get answerInvalid;

  /// Questionnaire: saving the answer failed. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your answer. Please try again.'**
  String get answerSaveFailed;

  /// Questionnaire: confirm the suggested country. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get answerYes;

  /// Questionnaire: no second nationality. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get answerNo;

  /// Questionnaire: the suggested country is wrong, open the country list. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'No, another country'**
  String get countryNoOther;

  /// Questionnaire: has a second nationality, open the country list. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Yes, choose the country'**
  String get countryYesChoose;

  /// Questionnaire: the chosen second nationality. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Yes: {country}'**
  String countryYesChosen(String country);

  /// Questionnaire: limit on a multi-select question. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to {max} ({left} left)'**
  String multiPickUpTo(int max, int left);

  /// Questionnaire: field to type an answer that is not in the list. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Add your own'**
  String get multiAddOwn;

  /// Answer error: nothing picked on a multi-select. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please pick at least one.'**
  String get answerPickOne;

  /// Questionnaire: the chosen partner age range. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} years'**
  String rangeYears(int min, int max);

  /// Self-introduction: hint in the text field. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Your introduction…'**
  String get selfIntroHint;

  /// Self-introduction: send the text to Khalty. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get selfIntroSend;

  /// Self-introduction: skip it (the user can add a bio later). Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get selfIntroSkip;

  /// Self-introduction: the AI or saving failed; nothing was saved. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Khalty couldn\'t finish just now.'**
  String get selfIntroFailed;

  /// Button to repeat a failed action. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Review: Khalty's line when no message was saved with the analysis. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Here is what I understood about you, {name} 🌸'**
  String reviewFallbackReply(String name);

  /// Review: title of Khalty's summary of the user. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Your summary'**
  String get reviewSummary;

  /// Review: title of the bio matches will see. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'About me · shown on your card'**
  String get reviewAboutMe;

  /// Review: shown when the introduction was skipped. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'You can add an \"About me\" later from your profile.'**
  String get reviewNoAboutMe;

  /// Review: title of contradictions between the introduction and the answers. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Please check'**
  String get reviewPleaseCheck;

  /// Review: opens the edit menu. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reviewEdit;

  /// Review edit menu: back to the self-introduction. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Rewrite my introduction'**
  String get reviewRewriteIntro;

  /// Review edit menu: disabled until profile editing exists. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Change an answer (coming soon)'**
  String get reviewChangeAnswer;

  /// Review: finishes onboarding (from the old app). Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'That\'s me ✓'**
  String get reviewConfirm;

  /// Review: Khalty's texts were written in English but the app is in another language. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Written in English'**
  String get writtenInEnglish;

  /// Review: Khalty's texts were written in Arabic but the app is in another language. Arabic needs review.
  ///
  /// In en, this message translates to:
  /// **'Written in Arabic'**
  String get writtenInArabic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
