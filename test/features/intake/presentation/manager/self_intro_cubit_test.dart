import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_state.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/data/repos/fake_khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';

import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();
  final resolver = OnboardingStageResolver(config);
  final now = DateTime.utc(2026, 11, 18, 9);
  const intro =
      'I am a teacher in Riyadh. I love reading, cooking for my family and '
      'long walks by the sea. I hope to build a calm and faithful home.';
  late LocalProfileRepository profiles;
  late _RecordingAi ai;

  Future<SelfIntroCubit> build({UserProfile? profile}) async {
    profiles = LocalProfileRepository(await mockPrefs());
    addTearDown(profiles.dispose);
    await profiles.save(profile ?? profileAt(OnboardingStage.needsIntake));
    // A finished questionnaire, no introduction yet.
    if (profile == null) {
      final p = profileAt(OnboardingStage.needsSelfIntro);
      await profiles.save(p);
    }
    ai = _RecordingAi();
    final cubit = SelfIntroCubit(
      profiles: profiles,
      ai: ai,
      engineFor: resolver.engineFor,
      now: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  OnboardingStage stage() => resolver.resolve(testUser, profiles.current);

  test('starts writing, with Khalty\'s lines and the name', () async {
    final cubit = await build();
    expect(cubit.state.phase, SelfIntroPhase.writing);
    expect(cubit.state.name, 'Sara');
    expect(cubit.state.draft, isEmpty);
  });

  test('send: everything is saved together, then the review', () async {
    final cubit = await build();
    await cubit.send('  $intro  ', AppLanguage.en);

    expect(cubit.state.phase, SelfIntroPhase.done);
    final saved = profiles.current!;
    expect(saved.selfIntro, SelfIntro.typed(intro, at: now));
    expect(saved.analysis, isNotNull);
    expect(saved.progress.selfIntroDoneAt, now);
    expect(stage(), OnboardingStage.needsReview);
  });

  test('the AI gets the answers in English and the language', () async {
    final cubit = await build();
    await cubit.send(intro, AppLanguage.ar);
    final request = ai.requests.single;
    expect(request.language, AppLanguage.ar);
    expect(request.name, 'Sara');
    expect(request.introduction, intro);
    expect(request.answers['marital_status'], isA<String>());
    expect(request.mustAccept, isFalse);
  });

  test(
    'asked once for more: the text is kept, the next try accepted',
    () async {
      final cubit = await build();
      await cubit.send('hello', AppLanguage.en);
      expect(cubit.state.phase, SelfIntroPhase.needsMore);
      expect(cubit.state.khaltyReply, contains('Sara'));
      expect(cubit.state.draft, 'hello');
      expect(profiles.current!.analysis, isNull);

      await cubit.send('hello again', AppLanguage.en);
      expect(ai.requests.last.mustAccept, isTrue);
      expect(cubit.state.phase, SelfIntroPhase.done);
    },
  );

  test('skip: analysed from the answers, saved as skipped', () async {
    final cubit = await build();
    await cubit.skip(AppLanguage.en);
    expect(ai.requests.single.introduction, isNull);
    expect(profiles.current!.selfIntro, SelfIntro.skipped(at: now));
    expect(profiles.current!.analysis!.aboutMe, isNull);
    expect(stage(), OnboardingStage.needsReview);
  });

  test('an AI failure saves nothing; Try again repeats it', () async {
    final cubit = await build();
    ai.fail = true;
    await cubit.send(intro, AppLanguage.en);
    expect(cubit.state.phase, SelfIntroPhase.failed);
    expect(profiles.current!.selfIntro, isNull);

    ai.fail = false;
    await cubit.retry(AppLanguage.en);
    expect(ai.requests.last.introduction, intro);
    expect(cubit.state.phase, SelfIntroPhase.done);
  });

  test('empty text is not sent', () async {
    final cubit = await build();
    await cubit.send('   ', AppLanguage.en);
    expect(ai.requests, isEmpty);
    expect(cubit.state.phase, SelfIntroPhase.writing);
  });

  test('rewriting starts from the earlier introduction', () async {
    final earlier = profileAt(OnboardingStage.needsSelfIntro)
        .copyWith(selfIntro: SelfIntro.typed('My earlier words', at: now));
    final cubit = await build(profile: earlier);
    expect(cubit.state.draft, 'My earlier words');
  });
}

/// The fake AI without delay, remembering every request.
class _RecordingAi extends FakeKhaltyAiRepository {
  _RecordingAi() : super(delay: Duration.zero);

  final requests = <IntakeAnalysisRequest>[];

  @override
  Future<IntakeAnalysisResult> analyseIntake(IntakeAnalysisRequest request) {
    requests.add(request);
    return super.analyseIntake(request);
  }
}
