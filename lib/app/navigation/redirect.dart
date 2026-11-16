import 'package:khalty_ai_matchmaker/app/navigation/app_routes.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';

/// The screen each stage starts on.
String homeForStage(OnboardingStage stage) => switch (stage) {
  OnboardingStage.needsSignUp => AppRoutes.welcome,
  OnboardingStage.needsIntake => AppRoutes.intake,
  OnboardingStage.needsSelfIntro => AppRoutes.selfIntro,
  OnboardingStage.needsReview => AppRoutes.review,
  OnboardingStage.complete => AppRoutes.khalty,
};

/// Where to send the user instead of [location], or null to allow it.
/// Each stage may only visit its own screens.
String? resolveRedirect(OnboardingStage stage, String location) {
  final allowed = switch (stage) {
    OnboardingStage.needsSignUp =>
      location == AppRoutes.welcome ||
          location == AppRoutes.signUp ||
          location == AppRoutes.verifyCode,
    OnboardingStage.needsIntake => location == AppRoutes.intake,
    OnboardingStage.needsSelfIntro => location == AppRoutes.selfIntro,
    OnboardingStage.needsReview => location == AppRoutes.review,
    OnboardingStage.complete => location.startsWith(AppRoutes.homePrefix),
  };
  return allowed ? null : homeForStage(stage);
}
