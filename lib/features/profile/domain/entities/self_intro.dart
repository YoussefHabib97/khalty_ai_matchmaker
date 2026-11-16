enum SelfIntroSource {
  typed,
  voice;

  static SelfIntroSource fromName(Object? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => typed);
}

/// The user's self-introduction at the end of the questionnaire: typed (or,
/// later, a voice transcript), or skipped. Voice audio itself is never kept.
/// The three constructors only allow valid combinations.
class SelfIntro {
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

  /// Null when [skipped].
  final String? text;
  final SelfIntroSource source;
  final bool skipped;
  final DateTime at;

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
