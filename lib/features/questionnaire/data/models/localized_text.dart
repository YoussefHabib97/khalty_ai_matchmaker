import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/config_exception.dart';

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

/// A config text in English and Arabic. In the file, each language is either
/// a string or `{"male": ..., "female": ...}`; the version is picked by the
/// **user's** gender.
class LocalizedText {
  const LocalizedText({required this.en, required this.ar});

  /// Parses and checks a text at [path]: both languages present, gendered
  /// versions complete, no unknown placeholders.
  factory LocalizedText.fromJson(Object? json, String path) {
    if (json is! Map) {
      throw ConfigException(path, 'expected {"en": ..., "ar": ...}');
    }
    for (final key in json.keys) {
      if (key != 'en' && key != 'ar') {
        throw ConfigException('$path.$key', 'unknown language (use en/ar)');
      }
    }
    return LocalizedText(
      en: _language(json['en'], '$path.en'),
      ar: _language(json['ar'], '$path.ar'),
    );
  }

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
    if (vars.isEmpty) return raw;
    return raw.replaceAllMapped(_placeholder, (m) => vars[m[1]] ?? m[0]!);
  }

  static GenderedText _language(Object? json, String path) {
    if (json is String) return GenderedText.same(_text(json, path));
    if (json is Map) {
      for (final key in json.keys) {
        if (key != 'male' && key != 'female') {
          throw ConfigException('$path.$key', 'use "male" and "female" only');
        }
      }
      return GenderedText(
        _text(json['male'], '$path.male'),
        _text(json['female'], '$path.female'),
      );
    }
    throw ConfigException(path, 'missing text');
  }

  static String _text(Object? json, String path) {
    if (json is! String || json.trim().isEmpty) {
      throw ConfigException(path, 'missing text');
    }
    for (final m in _placeholder.allMatches(json)) {
      if (!kConfigPlaceholders.contains(m[1])) {
        throw ConfigException(
          path,
          'unknown placeholder {${m[1]}} '
          '(allowed: ${kConfigPlaceholders.map((p) => '{$p}').join(', ')})',
        );
      }
    }
    return json;
  }
}

/// A list of alternative texts per language (e.g. Khalty's short
/// acknowledgements, one picked at random).
class LocalizedTextList {
  const LocalizedTextList({required this.en, required this.ar});

  factory LocalizedTextList.fromJson(Object? json, String path) {
    if (json is! Map) {
      throw ConfigException(path, 'expected {"en": [...], "ar": [...]}');
    }
    List<String> lang(String code) {
      final list = json[code];
      if (list is! List || list.isEmpty) {
        throw ConfigException('$path.$code', 'expected a non-empty list');
      }
      return List.unmodifiable([
        for (var i = 0; i < list.length; i++)
          LocalizedText._text(list[i], '$path.$code[$i]'),
      ]);
    }

    return LocalizedTextList(en: lang('en'), ar: lang('ar'));
  }

  final List<String> en;
  final List<String> ar;

  List<String> forLanguage(AppLanguage language) =>
      language == AppLanguage.ar ? ar : en;
}
