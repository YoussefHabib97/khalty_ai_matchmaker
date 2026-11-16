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

  @override
  String get welcomeMeet => 'تعرّف على خالتي';

  @override
  String get welcomeTagline => 'خطّابتك الشخصية 💍';

  @override
  String get welcomeTitle => 'اعثر على شريك حياتك، ترشيح واحد في كل مرة';

  @override
  String get welcomeBody =>
      'دردش مع خالتي. تتعرّف على ما يهمّك وتقدّم لك ترشيحًا مدروسًا واحدًا في كل مرة.';

  @override
  String get getStarted => 'ابدأ الآن ♥';

  @override
  String get genderQuestion => 'أنا…';

  @override
  String get genderMan => 'رجل';

  @override
  String get genderWoman => 'امرأة';

  @override
  String get phoneLabel => 'رقم الجوال';

  @override
  String get consentText =>
      'أوافق على أن خالتي حاضرة في محادثاتي لتحافظ على سلامتها وقد تقدّم لي نصائح خاصة، وأن بياناتي محفوظة بأمان ولا تُشارك دون موافقتي.';

  @override
  String get sendCode => 'أرسل الرمز';

  @override
  String get errorPickGender => 'اختر رجل أو امرأة';

  @override
  String get errorPhoneInvalid => 'من فضلك أدخل رقم جوال صحيحًا.';

  @override
  String get errorAgreeFirst => 'من فضلك وافق على الشروط للمتابعة.';

  @override
  String get errorSendFailed =>
      'تعذّر إرسال الرمز. تحقق من الرقم وحاول مرة أخرى.';

  @override
  String get errorCodeWrong => 'الرمز غير صحيح. حاول مرة أخرى.';

  @override
  String get errorCodeExpired => 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.';

  @override
  String get errorTooManyAttempts =>
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String codeSentTo(String phone) {
    return 'أرسلنا رمزًا من 6 أرقام برسالة نصية إلى $phone.';
  }

  @override
  String get codeLabel => 'الرمز المكوّن من 6 أرقام';

  @override
  String get verifyButton => 'تحقق';

  @override
  String get resendCode => 'أعد إرسال الرمز';

  @override
  String resendIn(String time) {
    return 'إعادة الإرسال بعد $time';
  }

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String testCodeHint(String code) {
    return 'رمز التجربة: $code';
  }

  @override
  String get chooseCountry => 'اختر الدولة';

  @override
  String get countrySearchHint => 'ابحث عن دولة';

  @override
  String get countriesCommon => 'الأكثر استخدامًا';

  @override
  String get countriesAll => 'كل الدول';

  @override
  String get countriesNoResults => 'لا توجد دول مطابقة';
}
