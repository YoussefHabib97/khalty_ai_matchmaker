import 'package:khalty_ai_matchmaker/core/utils/json_dates.dart';

enum SelfIntroSource {
  typed,
  voice;

  static SelfIntroSource fromName(Object? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => typed);
}

/// The user's self-introduction at the end of the questionnaire: typed (or,
/// later, a voice transcript), or skipped. Voice audio itself is never kept.
class SelfIntro {
  const SelfIntro._({
    required this.text,
    required this.source,
    required this.skipped,
    required this.at,
  });

  const SelfIntro.typed(String this.text, {required this.at})
    : source = SelfIntroSource.typed,
      skipped = false;

  const SelfIntro.voice(String this.text, {required this.at})
    : source = SelfIntroSource.voice,
      skipped = false;

  const SelfIntro.skipped({required this.at})
    : text = null,
      source = SelfIntroSource.typed,
      skipped = true;

  factory SelfIntro.fromJson(Map<String, Object?> json) => SelfIntro._(
    text: json['text'] as String?,
    source: SelfIntroSource.fromName(json['source']),
    skipped: json['skipped'] as bool? ?? false,
    at: dateFromJson(json['at']),
  );

  /// Null when [skipped].
  final String? text;
  final SelfIntroSource source;
  final bool skipped;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'text': text,
    'source': source.name,
    'skipped': skipped,
    'at': dateToJson(at),
  };

  @override
  bool operator ==(Object other) =>
      other is SelfIntro &&
      other.text == text &&
      other.source == source &&
      other.skipped == skipped &&
      other.at == at;
  @override
  int get hashCode => Object.hash(text, source, skipped, at);
}
