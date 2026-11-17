import 'package:khalty_ai_matchmaker/core/constants/enums.dart';

/// Placeholders the app fills in. Anything else in `{braces}` is a typo.
const kConfigPlaceholders = {'name', 'detected', 'residence'};

final _placeholder = RegExp(r'\{(\w+)\}');

/// One language's text: the same for everyone, or one version per gender.
class GenderedText {
  const GenderedText(this.male, this.female);
  const GenderedText.same(String text) : male = text, female = text;

  final String male;
  final String female;

  bool get isGendered => male != female;
  String forGender(Gender gender) => gender == Gender.male ? male : female;
}

/// A text in English and Arabic, each optionally with a version per gender.
/// The version is picked by the **user's** gender.
class LocalizedText {
  const LocalizedText({required this.en, required this.ar});

  final GenderedText en;
  final GenderedText ar;

  /// The text for [language] and the user's [gender], with placeholders
  /// replaced from [vars] (unknown or missing ones are left as-is).
  String resolve(
    AppLanguage language,
    Gender gender, {
    Map<String, String> vars = const {},
  }) {
    final raw = (language == AppLanguage.ar ? ar : en).forGender(gender);
    return _fill(raw, vars);
  }
}

String _fill(String raw, Map<String, String> vars) => vars.isEmpty
    ? raw
    : raw.replaceAllMapped(_placeholder, (m) => vars[m[1]] ?? m[0]!);

/// Alternative texts per language (e.g. Khalty's short acknowledgements,
/// one picked at random).
class LocalizedTextList {
  LocalizedTextList({required List<String> en, required List<String> ar})
    : en = List.unmodifiable(en),
      ar = List.unmodifiable(ar);

  final List<String> en;
  final List<String> ar;

  List<String> forLanguage(AppLanguage language) =>
      language == AppLanguage.ar ? ar : en;

  /// Text number [index] (wrapping around) for [language], with placeholders
  /// replaced from [vars]. Cycling by index never repeats a text twice in a
  /// row.
  String resolve(
    AppLanguage language,
    int index, {
    Map<String, String> vars = const {},
  }) {
    final texts = forLanguage(language);
    return _fill(texts[index % texts.length], vars);
  }
}
