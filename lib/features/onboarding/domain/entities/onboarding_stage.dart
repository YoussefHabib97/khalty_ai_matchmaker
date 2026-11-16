/// Where the user is in onboarding. Always worked out from saved data
/// (see `OnboardingStageResolver`), never stored.
enum OnboardingStage {
  /// Not signed in, or signed in without a profile yet.
  needsSignUp,

  /// The questionnaire has unanswered questions.
  needsIntake,

  /// No self-introduction yet, or no analysis of it yet.
  needsSelfIntro,

  /// Analysis done; waiting for "That's me".
  needsReview,

  /// Onboarding finished; the main app.
  complete,
}
