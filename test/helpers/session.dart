import 'dart:convert';

import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/user_profile_mapper.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

import 'questionnaire.dart';

final sessionTime = DateTime.utc(2026, 11, 16, 10);

const testUser = AuthUser(uid: 'fake-966500000002', phoneE164: '+966500000002');

/// A profile for [testUser] that has reached [stage].
UserProfile profileAt(OnboardingStage stage, {Gender gender = Gender.female}) {
  var profile = UserProfile(
    uid: testUser.uid,
    gender: gender,
    phoneE164: testUser.phoneE164,
    consent: Consent(version: Consent.currentVersion, acceptedAt: sessionTime),
  );
  if (stage.index <= OnboardingStage.needsIntake.index) return profile;

  final engine = QuestionnaireEngine(loadRealConfig(), gender);
  profile = profile.copyWith(
    answers: QuestionnaireAutofill.answerAll(engine),
    progress: profile.progress.copyWith(intakeDoneAt: sessionTime),
  );
  if (stage == OnboardingStage.needsSelfIntro) return profile;

  profile = profile.copyWith(
    selfIntro: SelfIntro.typed('Hello', at: sessionTime),
    analysis: IntakeAnalysis(
      aboutMe: 'Bio',
      traits: const [],
      brief: 'Brief',
      language: AppLanguage.en,
      generatedAt: sessionTime,
    ),
    progress: profile.progress.copyWith(selfIntroDoneAt: sessionTime),
  );
  if (stage == OnboardingStage.needsReview) return profile;

  return profile.copyWith(
    progress: profile.progress.copyWith(confirmedAt: sessionTime),
  );
}

/// Stored values (for `SharedPreferences.setMockInitialValues`) of a signed-in
/// [testUser] whose profile has reached [stage].
Map<String, Object> storedSessionAt(OnboardingStage stage) =>
    stage == OnboardingStage.needsSignUp
    ? {FakeAuthRepository.sessionKey: _storedUser}
    : storedSession(profileAt(stage));

/// Stored values of a signed-in [testUser] with [profile] (same uid).
Map<String, Object> storedSession(UserProfile profile) => {
  FakeAuthRepository.sessionKey: _storedUser,
  LocalProfileRepository.key: jsonEncode(UserProfileMapper.toJson(profile)),
};

final _storedUser = jsonEncode({
  'uid': testUser.uid,
  'phone': testUser.phoneE164,
});
