import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_cubit.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';

import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final resolver = OnboardingStageResolver(loadRealConfig());
  final now = DateTime.utc(2026, 11, 18, 9);
  late LocalProfileRepository profiles;

  Future<ReviewCubit> build() async {
    profiles = LocalProfileRepository(await mockPrefs());
    addTearDown(profiles.dispose);
    await profiles.save(profileAt(OnboardingStage.needsReview));
    final cubit = ReviewCubit(profiles: profiles, now: () => now);
    addTearDown(cubit.close);
    return cubit;
  }

  OnboardingStage stage() => resolver.resolve(testUser, profiles.current);

  test('shows the saved analysis', () async {
    final cubit = await build();
    expect(cubit.state.analysis, profiles.current!.analysis);
    expect(cubit.state.isSaving, isFalse);
  });

  test('"That\'s me" finishes onboarding', () async {
    final cubit = await build();
    await cubit.confirm();
    expect(profiles.current!.progress.confirmedAt, now);
    expect(stage(), OnboardingStage.complete);
  });

  test('"Rewrite my introduction" goes back, keeping the text', () async {
    final cubit = await build();
    final text = profiles.current!.selfIntro!.text;
    await cubit.rewriteIntroduction();
    expect(profiles.current!.analysis, isNull);
    expect(profiles.current!.progress.selfIntroDoneAt, isNull);
    expect(profiles.current!.selfIntro!.text, text);
    expect(stage(), OnboardingStage.needsSelfIntro);
  });
}
