import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/contact_sanitizer.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/repos/khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';

/// An offline stand-in for Khalty's AI with canned, templated output in
/// English and Arabic. It behaves like the real thing where the app can
/// tell: a delay, asking once for more when the introduction is too thin, a
/// bio from the user's own words without contact details, and one demo
/// contradiction (mentions smoking but answered "No").
class FakeKhaltyAiRepository implements KhaltyAiRepository {
  FakeKhaltyAiRepository({
    this.delay = const Duration(seconds: 2),
    this.fail = false,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Introductions shorter than this are judged too thin (first try only).
  static const minWords = 10;

  final Duration delay;

  /// Throw [KhaltyAiException] on every call (for tests).
  bool fail;
  final DateTime Function() _now;

  @override
  Future<IntakeAnalysisResult> analyseIntake(
    IntakeAnalysisRequest request,
  ) async {
    await Future<void>.delayed(delay);
    if (fail) throw const KhaltyAiException('Fake failure');

    final intro = request.introduction?.trim();
    final t = _Texts(request);
    if (intro != null && !request.mustAccept && _tooThin(intro)) {
      return IntroNeedsMore(t.askMore());
    }

    final mismatches = [
      if (intro != null &&
          request.answers['smoking'] == 'No' &&
          _mentionsSmoking.hasMatch(intro))
        t.smokingMismatch(),
    ];
    return IntakeAnalysed(
      IntakeAnalysis(
        aboutMe: intro == null ? null : _bio(intro),
        traits: t.traits(introduced: intro != null),
        brief: t.brief(introduced: intro != null),
        mismatches: mismatches,
        language: request.language,
        generatedAt: _now(),
        reply: t.reply(
          introduced: intro != null,
          hasMismatch: mismatches.isNotEmpty,
        ),
      ),
    );
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _mentionsSmoking = RegExp(
    r'smok|cigar|shisha|hookah|vap(e|ing)|تدخين|ادخن|أدخن|سجائر|سيجار|شيشة|معسل',
    caseSensitive: false,
  );

  static bool _tooThin(String intro) =>
      !_letter.hasMatch(intro) ||
      intro.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length < minWords;

  /// The user's own words: contact details removed, at most 5 sentences.
  static String _bio(String intro) {
    final clean = ContactInfoSanitizer.sanitize(intro).text;
    final sentences = RegExp(r'[^.!?؟]+[.!?؟]*')
        .allMatches(clean.replaceAll(RegExp(r'\s+'), ' '))
        .map((m) => m[0]!.trim())
        .where((s) => s.isNotEmpty)
        .take(5);
    return sentences.join(' ');
  }
}

/// The fake's templates, per language and gender.
class _Texts {
  _Texts(this.r);

  final IntakeAnalysisRequest r;

  bool get _ar => r.language == AppLanguage.ar;
  bool get _man => r.gender == Gender.male;
  String get _name => r.name;

  /// Arabic verb/adjective by the user's gender.
  String _g(String male, String female) => _man ? male : female;

  String? get _country => switch (r.answers['country']) {
    final String iso => countryByIso(iso)?.name(r.language),
    _ => null,
  };

  ({Object? min, Object? max})? get _partnerAge =>
      switch (r.answers['partner_age']) {
        final Map<Object?, Object?> range => (
          min: range['min'],
          max: range['max'],
        ),
        _ => null,
      };

  String askMore() => _ar
      ? 'شكرًا يا $_name 🌸 ${_g('هل يمكن أن تخبرني', 'هل يمكن أن تخبريني')} بالمزيد؟ '
            'بضع جمل عن نفسك، وحياتك اليومية، وما ${_g('تحب', 'تحبين')} أن '
            '${_g('تعرفه زوجتك', 'يعرفه زوجك')} المستقبلي${_g('ة', '')} ستساعدني كثيرًا.'
      : 'Thank you, $_name 🌸 Could you tell me a little more? A few sentences '
            'about who you are, your daily life, and what you would like your '
            'future ${_man ? 'wife' : 'husband'} to know would help me a lot.';

  String smokingMismatch() => _ar
      ? 'ورد ذكر التدخين في تعريفك، بينما كانت إجابتك عن سؤال التدخين «لا».'
      : 'You mentioned smoking in your introduction, but answered "No" to '
            'the smoking question.';

  List<Trait> traits({required bool introduced}) => [
    _ar
        ? Trait(
            label: _g('مهتم بالتفاصيل', 'مهتمة بالتفاصيل'),
            reason: _g('أجاب عن كل سؤال بعناية', 'أجابت عن كل سؤال بعناية'),
          )
        : const Trait(
            label: 'Thoughtful',
            reason: 'answered every question with care',
          ),
    if (introduced)
      _ar
          ? Trait(
              label: _g('صريح', 'صريحة'),
              reason: _g('تحدث بانفتاح في تعريفه', 'تحدثت بانفتاح في تعريفها'),
            )
          : const Trait(
              label: 'Open',
              reason: 'spoke openly in the introduction',
            ),
  ];

  String brief({required bool introduced}) {
    final age = r.answers['age'];
    final country = _country;
    final range = _partnerAge;
    final mustHaves = switch (r.answers['must_haves']) {
      final List<Object?> list when list.isNotEmpty => list.join(', '),
      _ => null,
    };
    final marital = r.answers['marital_status'];
    final lines = _ar
        ? [
            [
              _name,
              if (age != null) '$age سنة',
              if (country != null) '${_g('يقيم في', 'تقيم في')} $country',
            ].join('، '),
            if (range != null)
              '${_g('يبحث عن زوجة عمرها', 'تبحث عن زوج عمره')} بين '
                  '${range.min} و${range.max} سنة.',
            _g('أجاب عن أسئلة خالتي كلها.', 'أجابت عن أسئلة خالتي كلها.'),
            introduced
                ? _g(
                    'قدّم تعريفًا بنفسه بكلماته.',
                    'قدّمت تعريفًا بنفسها بكلماتها.',
                  )
                : _g(
                    'لم يكتب تعريفًا بنفسه بعد.',
                    'لم تكتب تعريفًا بنفسها بعد.',
                  ),
          ]
        : [
            [
              _name,
              if (age != null) '$age',
              if (country != null) 'lives in $country',
            ].join(', '),
            if (marital != null) '$marital.',
            if (range != null)
              'Looking for a ${_man ? 'wife' : 'husband'} aged '
                  '${range.min}–${range.max}.',
            if (mustHaves != null)
              'Values most in a spouse: ${mustHaves.toLowerCase()}.',
            introduced
                ? 'Shared a self-introduction in their own words.'
                : 'Skipped the self-introduction for now.',
          ];
    return lines.join('\n');
  }

  String reply({required bool introduced, required bool hasMismatch}) {
    if (_ar) {
      return [
        'شكرًا يا $_name 🌸',
        introduced
            ? 'استمتعت بقراءة ما كتبته عن نفسك.'
            : 'هذا كل ما أحتاجه الآن.',
        if (hasMismatch) 'أرجو مراجعة النقطة التي أشرت إليها في ملخصك.',
        'سأبحث الآن بعناية وأتواصل مع من يناسبك، وسأخبرك فور أن يرد أحد، '
            'عادةً خلال يوم أو يومين.',
      ].join(' ');
    }
    return [
      'Thank you, $_name 🌸',
      introduced
          ? 'I loved reading what you wrote about yourself.'
          : "That's everything I need for now.",
      if (hasMismatch) 'Please check the point I noted in your summary.',
      "I'll now search carefully and reach out to suitable people, and let "
          'you know as soon as someone responds, usually within a day or two.',
    ].join(' ');
  }
}
