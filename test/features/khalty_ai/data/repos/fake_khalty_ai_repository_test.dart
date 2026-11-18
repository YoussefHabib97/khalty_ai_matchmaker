import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/data/repos/fake_khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';

void main() {
  final now = DateTime.utc(2026, 11, 18, 9);
  late FakeKhaltyAiRepository ai;
  setUp(
    () => ai = FakeKhaltyAiRepository(delay: Duration.zero, now: () => now),
  );

  const goodIntro =
      'I am a primary school teacher in Riyadh. I love reading, cooking '
      'for my family and long walks. I hope to build a calm, faithful home.';
  const answers = <String, Object>{
    'name': 'Sara',
    'age': 30,
    'country': 'SA',
    'marital_status': 'Never married',
    'smoking': 'No',
    'partner_age': {'min': 29, 'max': 38},
    'must_haves': ['Religious', 'Kind'],
  };

  IntakeAnalysisRequest request({
    String? intro,
    bool mustAccept = false,
    AppLanguage language = AppLanguage.en,
    Gender gender = Gender.female,
  }) => IntakeAnalysisRequest(
    gender: gender,
    language: language,
    name: 'Sara',
    answers: answers,
    introduction: intro,
    mustAccept: mustAccept,
  );

  Future<IntakeAnalysis> analysed(IntakeAnalysisRequest r) async =>
      (await ai.analyseIntake(r) as IntakeAnalysed).analysis;

  test('a thin introduction gets one kind request for more', () async {
    final result = await ai.analyseIntake(request(intro: 'hi there'));
    expect(result, isA<IntroNeedsMore>());
    expect((result as IntroNeedsMore).reply, contains('Sara'));
    expect(
      await ai.analyseIntake(
        request(intro: '12345 67890 ... !!! ?? 1 2 3 4 5'),
      ),
      isA<IntroNeedsMore>(),
      reason: 'no letters at all',
    );
  });

  test('the second try is always accepted', () async {
    final result = await ai.analyseIntake(
      request(intro: 'hi there', mustAccept: true),
    );
    expect(result, isA<IntakeAnalysed>());
  });

  test('the bio is the user\'s own words without contact details', () async {
    final analysis = await analysed(
      request(intro: '$goodIntro Call me on 0501234567 or @sara_k.'),
    );
    expect(analysis.aboutMe, startsWith('I am a primary school teacher'));
    expect(analysis.aboutMe, isNot(contains('0501234567')));
    expect(analysis.aboutMe, isNot(contains('@sara_k')));
    expect(analysis.language, AppLanguage.en);
    expect(analysis.generatedAt, now);
    expect(analysis.traits, hasLength(2));
  });

  test('the brief uses the answers', () async {
    final brief = (await analysed(request(intro: goodIntro))).brief;
    expect(brief, contains('Sara, 30, lives in Saudi Arabia'));
    expect(brief, contains('husband aged 29–38'));
    expect(brief, contains('religious, kind'));
  });

  test('skipped: no bio, and the message says so', () async {
    final analysis = await analysed(request());
    expect(analysis.aboutMe, isNull);
    expect(analysis.reply, contains("That's everything I need"));
    expect(analysis.traits, hasLength(1));
  });

  test(
    'mentioning shisha after answering "No" to smoking is flagged',
    () async {
      final analysis = await analysed(
        request(intro: '$goodIntro On weekends I enjoy shisha with friends.'),
      );
      expect(analysis.mismatches, hasLength(1));
      expect(analysis.reply, contains('Please check'));
      expect((await analysed(request(intro: goodIntro))).mismatches, isEmpty);
    },
  );

  test('writes in Arabic, by the user\'s gender', () async {
    final woman = await analysed(request(language: AppLanguage.ar));
    expect(woman.language, AppLanguage.ar);
    expect(woman.brief, contains('تقيم في السعودية'));
    final man = await analysed(
      request(language: AppLanguage.ar, gender: Gender.male),
    );
    expect(man.brief, contains('يقيم في السعودية'));
    expect(man.brief, contains('يبحث عن زوجة'));
  });

  test('can be told to fail', () async {
    ai.fail = true;
    expect(
      () => ai.analyseIntake(request(intro: goodIntro)),
      throwsA(isA<KhaltyAiException>()),
    );
  });
}
