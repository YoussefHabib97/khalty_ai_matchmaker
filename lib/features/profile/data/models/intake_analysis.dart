import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/collections.dart';
import 'package:khalty_ai_matchmaker/core/utils/json_dates.dart';

/// One of Khalty's private impressions of the user ("trait – reason").
class Trait {
  const Trait({required this.label, required this.reason});

  factory Trait.fromJson(Map<String, Object?> json) =>
      Trait(label: json['label'] as String, reason: json['reason'] as String);

  final String label;
  final String reason;

  Map<String, Object?> toJson() => {'label': label, 'reason': reason};

  @override
  bool operator ==(Object other) =>
      other is Trait && other.label == label && other.reason == reason;
  @override
  int get hashCode => Object.hash(label, reason);
}

/// What Khalty produced from the answers and self-introduction.
class IntakeAnalysis {
  IntakeAnalysis({
    required this.aboutMe,
    required List<Trait> traits,
    required this.brief,
    List<String> mismatches = const [],
    required this.language,
    required this.generatedAt,
  }) : traits = List.unmodifiable(traits),
       mismatches = List.unmodifiable(mismatches) {
    if (traits.length > maxTraits) {
      throw ArgumentError('At most $maxTraits traits, got ${traits.length}');
    }
  }

  factory IntakeAnalysis.fromJson(Map<String, Object?> json) => IntakeAnalysis(
    aboutMe: json['aboutMe'] as String,
    traits: [
      for (final t in (json['traits'] as List? ?? const []).take(maxTraits))
        Trait.fromJson(Map<String, Object?>.from(t as Map)),
    ],
    brief: json['brief'] as String,
    mismatches: List<String>.from(json['mismatches'] as List? ?? const []),
    language: AppLanguage.fromCode(json['language']),
    generatedAt: dateFromJson(json['generatedAt']),
  );

  static const maxTraits = 4;

  /// First-person bio (3–5 sentences) suggested for the profile card.
  final String aboutMe;

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

  Map<String, Object?> toJson() => {
    'aboutMe': aboutMe,
    'traits': [for (final t in traits) t.toJson()],
    'brief': brief,
    'mismatches': mismatches,
    'language': language.code,
    'generatedAt': dateToJson(generatedAt),
  };

  @override
  bool operator ==(Object other) =>
      other is IntakeAnalysis &&
      other.aboutMe == aboutMe &&
      listEquals(other.traits, traits) &&
      other.brief == brief &&
      listEquals(other.mismatches, mismatches) &&
      other.language == language &&
      other.generatedAt == generatedAt;
  @override
  int get hashCode => Object.hash(
    aboutMe,
    Object.hashAll(traits),
    brief,
    Object.hashAll(mismatches),
    language,
    generatedAt,
  );
}
