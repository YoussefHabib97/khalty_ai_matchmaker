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

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get intakeBegin => 'لنبدأ';

  @override
  String get intakeContinue => 'متابعة';

  @override
  String get intakeSkip => 'أفضّل عدم الإجابة';

  @override
  String get intakeWhyThisQuestion => 'لماذا هذا السؤال؟';

  @override
  String intakeChapterOf(int current, int total) {
    return 'الجزء $current من $total';
  }

  @override
  String intakeQuestionsLeft(int count) {
    return 'المتبقي: $count';
  }

  @override
  String get answerRequired => 'الإجابة مطلوبة للمتابعة.';

  @override
  String answerTooLong(int max) {
    return 'يجب ألا تزيد الإجابة على $max حرفًا.';
  }

  @override
  String get answerLettersOnly => 'يُقبل الاسم بالحروف فقط.';

  @override
  String answerNumberBetween(int min, int max) {
    return 'يجب أن يكون الرقم بين $min و$max.';
  }

  @override
  String get answerNumberRequired => 'يجب أن تكون الإجابة رقمًا.';

  @override
  String get answerInvalid =>
      'تعذّر قبول هذه الإجابة، يُرجى المحاولة مرة أخرى.';

  @override
  String get answerSaveFailed => 'تعذّر حفظ الإجابة، يُرجى المحاولة مرة أخرى.';

  @override
  String get answerYes => 'نعم';

  @override
  String get answerNo => 'لا';

  @override
  String get countryNoOther => 'لا، دولة أخرى';

  @override
  String get countryYesChoose => 'نعم، اختيار الدولة';

  @override
  String countryYesChosen(String country) {
    return 'نعم: $country';
  }

  @override
  String multiPickUpTo(int max, int left) {
    return 'يمكن اختيار $max كحد أقصى (المتبقي: $left)';
  }

  @override
  String get multiAddOwn => 'إضافة إجابة أخرى';

  @override
  String get answerPickOne => 'يُرجى اختيار إجابة واحدة على الأقل.';

  @override
  String rangeYears(int min, int max) {
    return 'من $min إلى $max سنة';
  }

  @override
  String get selfIntroHint => 'تعريفك بنفسك…';

  @override
  String get selfIntroSend => 'إرسال';

  @override
  String get selfIntroSkip => 'ليس الآن';

  @override
  String get selfIntroFailed => 'تعذّر على خالتي الإكمال الآن.';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String reviewFallbackReply(String name) {
    return 'هذا ما فهمته عنك يا $name 🌸';
  }

  @override
  String get reviewSummary => 'ملخصك';

  @override
  String get reviewAboutMe => 'نبذة عني · تظهر في بطاقتك';

  @override
  String get reviewNoAboutMe => 'يمكن إضافة نبذة عنك لاحقًا من ملفك الشخصي.';

  @override
  String get reviewPleaseCheck => 'يُرجى المراجعة';

  @override
  String get reviewEdit => 'تعديل';

  @override
  String get reviewRewriteIntro => 'إعادة كتابة تعريفي';

  @override
  String get reviewChangeAnswer => 'تغيير إجابة (قريبًا)';

  @override
  String get reviewConfirm => 'هذا أنا ✓';

  @override
  String get writtenInEnglish => 'مكتوب بالإنجليزية';

  @override
  String get writtenInArabic => 'مكتوب بالعربية';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String knowsYou(int percent) {
    return 'خالتي تعرفك بنسبة $percent%';
  }

  @override
  String get hintQuestions =>
      'الإجابة عن الأسئلة الجديدة تساعدني على إيجاد ترشيحات أفضل.';

  @override
  String get hintIntroduction =>
      'تعريفك بنفسك بكلماتك يساعدني على تقديمك بشكل أفضل.';

  @override
  String get hintAboutMe => 'نبذة قصيرة عنك تجعل بطاقتك أوضح.';

  @override
  String get hintPhoto => 'يمكن إضافة صورة متى شئت.';

  @override
  String get hintOptional =>
      'الإجابة عن الأسئلة الاختيارية تساعدني على معرفتك أكثر.';

  @override
  String get hintComplete => 'أعرفك جيدًا 🌸';

  @override
  String ageYears(int age) {
    return '$age سنة';
  }

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get meEditProfile => 'تعديل ملفي';

  @override
  String get mePreview => 'كيف تقدّمك خالتي';

  @override
  String get meAboutMe => 'نبذة عني';

  @override
  String get meNoAboutMe => 'لم تُضف بعد.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String signedInAs(String phone) {
    return 'مسجّل الدخول برقم $phone';
  }

  @override
  String get pauseProfile => 'إيقاف ملفي مؤقتًا';

  @override
  String get pauseProfileHint => 'إخفاء ملفك عن الترشيحات الجديدة. قريبًا.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmBody =>
      'إجاباتك محفوظة على هذا الجهاز فقط حاليًا، لذا سيؤدي تسجيل الخروج إلى حذفها.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get deleteAccount => 'حذف حسابي';

  @override
  String get answerSkipped => 'بدون إجابة';

  @override
  String get answerPrivate => 'لا يراها إلا خالتي';

  @override
  String get editPhotos => 'الصور';

  @override
  String get photosHintMan =>
      'ترى المرشحات اللواتي تقترحهن خالتي صورتك الرئيسية.';

  @override
  String get sharePhoto => 'مشاركة صورتي الرئيسية بعد قبولي';

  @override
  String get sharePhotoHint => 'حتى ذلك الحين تظهر صورتك الظلية فقط.';

  @override
  String get photoAdd => 'إضافة صورة';

  @override
  String get photoFromGallery => 'اختيار من المعرض';

  @override
  String get photoFromCamera => 'التقاط صورة';

  @override
  String get photoMakeMain => 'جعلها الصورة الرئيسية';

  @override
  String get photoDelete => 'حذف الصورة';

  @override
  String get photoMain => 'الرئيسية';

  @override
  String get photoFailed => 'تعذّرت إضافة الصورة، يُرجى المحاولة مرة أخرى.';

  @override
  String get aboutMeHint => 'بضع جمل عنك. تُحذف أرقام الهواتف والروابط.';

  @override
  String get aboutMeCleaned =>
      'أُزيلت بيانات التواصل؛ خالتي هي من تعرّف بك أولًا.';

  @override
  String get save => 'حفظ';

  @override
  String get discardTitle => 'تجاهل التغييرات؟';

  @override
  String get discard => 'تجاهل';

  @override
  String get keepEditing => 'متابعة التعديل';

  @override
  String get traitsTitle => 'انطباعات خالتي · خاصة';

  @override
  String get traitsHint => 'لا يراها إلا خالتي، وتساعدها على الاختيار لك.';

  @override
  String get nowApplies => 'أصبح هذا السؤال ينطبق عليك.';

  @override
  String get updatingSummary => 'خالتي تحدّث ملخصك…';

  @override
  String heightCm(int cm) {
    return '$cm سم';
  }

  @override
  String get previewIntro => 'هكذا تقدّمك خالتي لمن تقترحه عليك.';

  @override
  String get previewShowIn => 'عرض البطاقة باللغة';

  @override
  String get previewPhotoAfterAccept =>
      'تبقى صورتك مخفية حتى تقبلي، ثم تُشارَك صورتك الرئيسية.';

  @override
  String get previewPhotoPrivate =>
      'تبقى صورك خاصة: لا يرى المرشحون إلا الصورة الرمزية.';

  @override
  String get previewPrivate =>
      'لا يظهر على بطاقتك أبدًا: تفضيلاتك في شريك الحياة، وما لا تقبله، وتعريفك بنفسك، وانطباعات خالتي.';
}
