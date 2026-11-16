import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';

/// Who is signed in, their profile, and where they are in onboarding.
class SessionState {
  const SessionState({required this.stage, this.user, this.profile});

  final OnboardingStage stage;
  final AuthUser? user;
  final UserProfile? profile;

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      other.stage == stage &&
      other.user == user &&
      other.profile == profile;
  @override
  int get hashCode => Object.hash(stage, user, profile);
  @override
  String toString() => 'SessionState($stage, ${user?.uid})';
}
