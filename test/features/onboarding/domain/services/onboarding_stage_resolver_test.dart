import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';

import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final resolver = OnboardingStageResolver(loadRealConfig());

  test('no user or no profile means sign-up', () {
    expect(resolver.resolve(null, null), OnboardingStage.needsSignUp);
    expect(resolver.resolve(testUser, null), OnboardingStage.needsSignUp);
    expect(
      resolver.resolve(null, profileAt(OnboardingStage.complete)),
      OnboardingStage.needsSignUp,
    );
  });

  test('a profile from another account means sign-up', () {
    const other = AuthUser(uid: 'someone-else', phoneE164: '+20100000000');
    expect(
      resolver.resolve(other, profileAt(OnboardingStage.complete)),
      OnboardingStage.needsSignUp,
    );
  });

  test('each stage is recognised from the saved profile', () {
    for (final stage in [
      OnboardingStage.needsIntake,
      OnboardingStage.needsSelfIntro,
      OnboardingStage.needsReview,
      OnboardingStage.complete,
    ]) {
      expect(resolver.resolve(testUser, profileAt(stage)), stage);
    }
  });

  test('a self-intro without an analysis goes back to the self-intro', () {
    final profile = profileAt(OnboardingStage.needsReview)
        .copyWith(analysis: null);
    expect(resolver.resolve(testUser, profile), OnboardingStage.needsSelfIntro);
  });

  test('confirmed users stay complete even with unanswered questions', () {
    // As if a new required question had been added to the config.
    final profile = profileAt(OnboardingStage.complete);
    final missingOne = profile.copyWith(
      answers: profile.answers.remove('education'),
    );
    expect(resolver.resolve(testUser, missingOne), OnboardingStage.complete);
  });

  test('reuses one engine per gender', () {
    final g = profileAt(OnboardingStage.needsIntake).gender;
    expect(identical(resolver.engineFor(g), resolver.engineFor(g)), isTrue);
  });
}
