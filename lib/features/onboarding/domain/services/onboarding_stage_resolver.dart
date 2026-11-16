import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// Works out the [OnboardingStage] from the signed-in user and their profile.
class OnboardingStageResolver {
  OnboardingStageResolver(this._config);

  final QuestionnaireConfig _config;
  final _engines = <Gender, QuestionnaireEngine>{};

  /// The questionnaire engine for [gender] (created once, then reused).
  QuestionnaireEngine engineFor(Gender gender) =>
      _engines.putIfAbsent(gender, () => QuestionnaireEngine(_config, gender));

  OnboardingStage resolve(AuthUser? user, UserProfile? profile) {
    if (user == null || profile == null || profile.uid != user.uid) {
      return OnboardingStage.needsSignUp;
    }
    // Finished users stay finished, even if questions are added later; new
    // questions are offered in the Me tab instead.
    if (profile.progress.confirmedAt != null) return OnboardingStage.complete;
    if (engineFor(profile.gender).nextField(profile.answers) != null) {
      return OnboardingStage.needsIntake;
    }
    // No analysis yet (e.g. the app closed mid-analysis) means redo it.
    if (profile.selfIntro == null || profile.analysis == null) {
      return OnboardingStage.needsSelfIntro;
    }
    return OnboardingStage.needsReview;
  }
}
