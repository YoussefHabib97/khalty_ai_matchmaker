import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/collections.dart';

/// One of Khalty's private impressions of the user ("trait – reason").
class Trait {
  const Trait({required this.label, required this.reason});

  final String label;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is Trait && other.label == label && other.reason == reason;
  @override
  int get hashCode => Object.hash(label, reason);
}

/// What Khalty produced from the answers and self-introduction.
class IntakeAnalysis {
  IntakeAnalysis({
    this.aboutMe,
    required List<Trait> traits,
    required this.brief,
    List<String> mismatches = const [],
    required this.language,
    required this.generatedAt,
    this.reply,
  }) : traits = List.unmodifiable(traits),
       mismatches = List.unmodifiable(mismatches) {
    if (traits.length > maxTraits) {
      throw ArgumentError('At most $maxTraits traits, got ${traits.length}');
    }
  }

  static const maxTraits = 4;

  /// First-person bio (3–5 sentences) suggested for the profile card, from
  /// the self-introduction. Null when the introduction was skipped.
  final String? aboutMe;

  /// Private impressions, at most [maxTraits]. Never shown to others.
  final List<Trait> traits;

  /// Khalty's brief about the user (5–7 lines).
  final String brief;

  /// Contradictions between the self-introduction and the answers, for
  /// Khalty to raise gently (e.g. mentions shisha but answered "No" smoking).
  final List<String> mismatches;

  /// The language the texts above were written in.
  final AppLanguage language;
  final DateTime generatedAt;

  /// Khalty's message to the user after the analysis (thanks, what happens
  /// next). Shown on the review screen.
  final String? reply;

  /// A copy with a new [brief] (e.g. after the answers were edited).
  IntakeAnalysis copyWith({String? brief}) => IntakeAnalysis(
    aboutMe: aboutMe,
    traits: traits,
    brief: brief ?? this.brief,
    mismatches: mismatches,
    language: language,
    generatedAt: generatedAt,
    reply: reply,
  );

  @override
  bool operator ==(Object other) =>
      other is IntakeAnalysis &&
      other.aboutMe == aboutMe &&
      listEquals(other.traits, traits) &&
      other.brief == brief &&
      listEquals(other.mismatches, mismatches) &&
      other.language == language &&
      other.generatedAt == generatedAt &&
      other.reply == reply;
  @override
  int get hashCode => Object.hash(
    aboutMe,
    Object.hashAll(traits),
    brief,
    Object.hashAll(mismatches),
    language,
    generatedAt,
    reply,
  );
}
