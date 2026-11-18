import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_routes.dart';
import 'package:khalty_ai_matchmaker/app/navigation/redirect.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';

void main() {
  const all = [
    AppRoutes.welcome,
    AppRoutes.signUp,
    AppRoutes.verifyCode,
    AppRoutes.intake,
    AppRoutes.selfIntro,
    AppRoutes.review,
    AppRoutes.reviewEdit,
    AppRoutes.khalty,
    AppRoutes.matches,
    AppRoutes.chats,
    AppRoutes.me,
    AppRoutes.settings,
    AppRoutes.editProfile,
    '/',
    '/unknown',
  ];

  const allowed = {
    OnboardingStage.needsSignUp: {
      AppRoutes.welcome,
      AppRoutes.signUp,
      AppRoutes.verifyCode,
    },
    OnboardingStage.needsIntake: {AppRoutes.intake},
    OnboardingStage.needsSelfIntro: {AppRoutes.selfIntro},
    OnboardingStage.needsReview: {AppRoutes.review, AppRoutes.reviewEdit},
    OnboardingStage.complete: {
      AppRoutes.khalty,
      AppRoutes.matches,
      AppRoutes.chats,
      AppRoutes.me,
      AppRoutes.settings,
      AppRoutes.editProfile,
    },
  };

  for (final stage in OnboardingStage.values) {
    test('${stage.name}: only its own screens are allowed', () {
      for (final location in all) {
        final redirect = resolveRedirect(stage, location);
        if (allowed[stage]!.contains(location)) {
          expect(redirect, isNull, reason: '$location should be allowed');
        } else {
          expect(
            redirect,
            homeForStage(stage),
            reason: '$location should go to ${homeForStage(stage)}',
          );
        }
      }
    });

    test('${stage.name}: its home screen is itself allowed', () {
      expect(resolveRedirect(stage, homeForStage(stage)), isNull);
    });
  }
}
