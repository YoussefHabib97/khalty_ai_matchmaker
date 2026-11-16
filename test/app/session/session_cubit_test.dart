import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';

import '../../helpers/prefs.dart';
import '../../helpers/questionnaire.dart';
import '../../helpers/session.dart';

void main() {
  final resolver = OnboardingStageResolver(loadRealConfig());

  Future<(SessionCubit, FakeAuthRepository, LocalProfileRepository)> build(
    Map<String, Object> stored,
  ) async {
    final SharedPrefs prefs = await mockPrefs(stored);
    final auth = FakeAuthRepository(prefs, delay: Duration.zero);
    final profiles = LocalProfileRepository(prefs);
    final cubit = SessionCubit(
      auth: auth,
      profiles: profiles,
      resolver: resolver,
    );
    addTearDown(cubit.close);
    return (cubit, auth, profiles);
  }

  test('the first state comes from what is stored, with no waiting', () async {
    final (signedOut, _, _) = await build({});
    expect(signedOut.state.stage, OnboardingStage.needsSignUp);

    final (done, _, _) = await build(storedSessionAt(OnboardingStage.complete));
    expect(done.state.stage, OnboardingStage.complete);
    expect(done.state.user, testUser);
    expect(done.state.profile?.uid, testUser.uid);
  });

  test('moves through the stages as the profile is saved', () async {
    final (cubit, auth, profiles) = await build({});
    final stages = <OnboardingStage>[];
    cubit.stream.listen((s) => stages.add(s.stage));

    final request = await auth.sendCode(testUser.phoneE164);
    await auth.verifyCode(request, FakeAuthRepository.code);
    await profiles.save(profileAt(OnboardingStage.needsIntake));
    await profiles.save(profileAt(OnboardingStage.needsSelfIntro));
    await profiles.save(profileAt(OnboardingStage.needsReview));
    await profiles.save(profileAt(OnboardingStage.complete));
    await Future<void>.delayed(Duration.zero);

    expect(stages, [
      // Signed in but no profile yet: still sign-up (the user changed).
      OnboardingStage.needsSignUp,
      OnboardingStage.needsIntake,
      OnboardingStage.needsSelfIntro,
      OnboardingStage.needsReview,
      OnboardingStage.complete,
    ]);
  });

  test('signing out goes back to sign-up', () async {
    final (cubit, auth, _) = await build(
      storedSessionAt(OnboardingStage.complete),
    );
    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.stage, OnboardingStage.needsSignUp);
  });
}
