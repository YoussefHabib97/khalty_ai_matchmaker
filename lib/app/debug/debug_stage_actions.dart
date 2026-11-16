import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_autofill.dart';

/// DEBUG ONLY (removed in step 13): jumps through onboarding stages so every
/// redirect can be checked on a phone before the real screens exist.
class DebugStageActions {
  DebugStageActions({
    required this._auth,
    required this._profiles,
    required this._resolver,
  });

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final OnboardingStageResolver _resolver;

  /// Signs in with the fake code and creates a fresh profile.
  Future<void> signIn(Gender gender) async {
    final phone = gender == Gender.male ? '+966500000001' : '+966500000002';
    final request = await _auth.sendCode(phone);
    final user = await _auth.verifyCode(request, FakeAuthRepository.code);
    await _profiles.save(
      UserProfile(
        uid: user.uid,
        gender: gender,
        phoneE164: user.phoneE164,
        consent: Consent(
          version: Consent.currentVersion,
          acceptedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Answers every remaining question with simple valid answers.
  Future<void> answerAll() => _update((p) {
    final engine = _resolver.engineFor(p.gender);
    return p.copyWith(
      answers: QuestionnaireAutofill.answerAll(engine, start: p.answers),
      progress: p.progress.copyWith(intakeDoneAt: DateTime.now()),
    );
  });

  /// Adds a sample self-introduction and analysis.
  Future<void> addSelfIntro() => _update((p) {
    final now = DateTime.now();
    return p.copyWith(
      selfIntro: SelfIntro.typed('A sample self-introduction.', at: now),
      analysis: IntakeAnalysis(
        aboutMe: 'A sample bio written by Khalty.',
        traits: const [Trait(label: 'Kind', reason: 'Sample impression')],
        brief: 'A sample brief.',
        language: AppLanguage.en,
        generatedAt: now,
      ),
      progress: p.progress.copyWith(selfIntroDoneAt: now),
    );
  });

  /// Taps "That's me".
  Future<void> confirm() => _update(
    (p) =>
        p.copyWith(progress: p.progress.copyWith(confirmedAt: DateTime.now())),
  );

  /// Signs out and clears the profile.
  Future<void> reset() async {
    await _auth.signOut();
    await _profiles.clear();
  }

  Future<void> _update(UserProfile Function(UserProfile) change) async {
    final profile = _profiles.current;
    if (profile != null) await _profiles.save(change(profile));
  }
}
