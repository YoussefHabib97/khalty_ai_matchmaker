import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// The parts of a profile that make up "Khalty knows you X%", in the order
/// they are suggested when several are missing.
enum ProfilePart {
  /// Questions that apply but have no answer (e.g. added after onboarding).
  questions(50),

  /// The self-introduction in the user's own words (not skipped).
  introduction(20),

  /// A bio for the profile card.
  aboutMe(10),

  /// At least one photo.
  photo(10),

  /// Optional questions answered rather than skipped (height, sect).
  optionalDetails(10);

  const ProfilePart(this.weight);

  /// Share of the 100%. The weights add up to 100.
  final int weight;
}

/// How well Khalty knows the user.
class Completeness {
  const Completeness({required this.percent, required this.nextStep});

  /// 0–100.
  final int percent;

  /// The biggest missing part, to suggest next; null at 100%.
  final ProfilePart? nextStep;

  @override
  bool operator ==(Object other) =>
      other is Completeness &&
      other.percent == percent &&
      other.nextStep == nextStep;
  @override
  int get hashCode => Object.hash(percent, nextStep);
  @override
  String toString() => 'Completeness($percent%, next: $nextStep)';
}

/// Works out "Khalty knows you X%": a weighted score over [ProfilePart]s,
/// each counting fully or partly (questions and optional details by
/// fraction answered).
abstract final class ProfileCompleteness {
  static Completeness of(UserProfile profile, QuestionnaireEngine engine) {
    final answers = profile.answers;

    final applicable = [
      for (final f in engine.fields)
        if (engine.applies(f, answers)) f,
    ];
    final optional = applicable.where((f) => f.optional).toList();
    final answeredOptional = optional.where(
      (f) => answers[f.key] != null && answers[f.key] is! SkippedAnswer,
    );

    final filled = <ProfilePart, double>{
      ProfilePart.questions: engine.progress(answers).fraction,
      ProfilePart.introduction: profile.selfIntro?.skipped == false ? 1 : 0,
      ProfilePart.aboutMe: (profile.effectiveAboutMe ?? '').trim().isEmpty
          ? 0
          : 1,
      ProfilePart.photo: profile.photos.isEmpty ? 0 : 1,
      ProfilePart.optionalDetails: optional.isEmpty
          ? 1
          : answeredOptional.length / optional.length,
    };

    var score = 0.0;
    ProfilePart? next;
    var biggestGap = 0.0;
    for (final part in ProfilePart.values) {
      final share = filled[part]!;
      score += part.weight * share;
      final gap = part.weight * (1 - share);
      if (gap > biggestGap) {
        biggestGap = gap;
        next = part;
      }
    }
    return Completeness(percent: score.round(), nextStep: next);
  }
}
