import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/config_exception.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/localized_text.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

final _placeholder = RegExp(r'\{(\w+)\}');

const _inputNames = {
  InputType.text: 'text',
  InputType.number: 'number',
  InputType.range: 'range',
  InputType.choice: 'choice',
  InputType.multi: 'multi',
  InputType.country: 'country',
  InputType.countryOptional: 'country_optional',
};

const _fieldProperties = {
  'key', 'chapter', 'input', 'visibility', 'question', 'question_pick', //
  'why', 'invalid', 'options', 'gender', 'if', 'else_value', 'else_from',
  'optional', 'min', 'max', 'suggest', 'max_pick', 'allow_text',
  'needs_review',
};
const _optionProperties = {'id', 'label', 'gender'};
const _chapterProperties = {'id', 'title', 'intro'};
const _scriptProperties = {
  'greeting', 'acks', 'name_ack', 'self_intro', 'analysing', //
};
const _rootProperties = {'schema_version', 'chapters', 'fields', 'script'};

/// Turns the questionnaire JSON into a [QuestionnaireConfig], checking it
/// strictly. Throws [ConfigException] naming the exact place of the first
/// problem found.
class QuestionnaireConfigParser {
  const QuestionnaireConfigParser();

  static const supportedSchemaVersion = 2;

  QuestionnaireConfig parse(Object? json) {
    final root = _object(json, r'$');
    _checkProperties(root, _rootProperties, r'$');

    final version = root['schema_version'];
    if (version != supportedSchemaVersion) {
      throw ConfigException(
        'schema_version',
        'expected $supportedSchemaVersion, got $version',
      );
    }

    final chapters = _chapters(root['chapters']);
    final chapterIds = {for (final c in chapters) c.id};

    final fieldsJson = _list(root['fields'], 'fields', nonEmpty: true);
    final fields = <FieldDef>[];
    for (var i = 0; i < fieldsJson.length; i++) {
      fields.add(_field(fieldsJson[i], 'fields[$i]', chapterIds, fields));
    }

    return QuestionnaireConfig(
      chapters: chapters,
      fields: fields,
      script: _script(root['script']),
    );
  }

  List<ChapterDef> _chapters(Object? json) {
    final list = _list(json, 'chapters', nonEmpty: true);
    final chapters = <ChapterDef>[];
    for (var i = 0; i < list.length; i++) {
      final path = 'chapters[$i]';
      final c = _object(list[i], path);
      _checkProperties(c, _chapterProperties, path);
      final id = _int(c['id'], '$path.id');
      if (chapters.any((x) => x.id == id)) {
        throw ConfigException('$path.id', 'duplicate chapter id $id');
      }
      chapters.add(
        ChapterDef(
          id: id,
          title: _text(c['title'], '$path.title'),
          intro: c['intro'] == null ? null : _text(c['intro'], '$path.intro'),
        ),
      );
    }
    return chapters;
  }

  FieldDef _field(
    Object? json,
    String path,
    Set<int> chapterIds,
    List<FieldDef> earlier,
  ) {
    final f = _object(json, path);
    final key = _string(f['key'], '$path.key');
    if (earlier.any((e) => e.key == key)) {
      throw ConfigException('$path.key', 'duplicate key "$key"');
    }
    final at = '$path ("$key")';
    _checkProperties(f, _fieldProperties, at);

    final chapter = _int(f['chapter'], '$at.chapter');
    if (!chapterIds.contains(chapter)) {
      throw ConfigException('$at.chapter', 'chapter $chapter does not exist');
    }

    final input = _enum<InputType>(
      InputType.values,
      f['input'],
      '$at.input',
      (e) => _inputNames[e]!,
    );
    final visibility = _enum<FieldVisibility>(
      FieldVisibility.values,
      f['visibility'],
      '$at.visibility',
      (e) => e.name,
    );
    final gender = f['gender'] == null
        ? null
        : _enum<Gender>(
            Gender.values,
            f['gender'],
            '$at.gender',
            (e) => e.name,
          );

    // Options.
    final options = <OptionDef>[];
    if (input.hasOptions) {
      final list = _list(f['options'], '$at.options', nonEmpty: true);
      for (var i = 0; i < list.length; i++) {
        final opt = _option(list[i], '$at.options[$i]');
        if (options.any((o) => o.id == opt.id)) {
          throw ConfigException('$at.options[$i].id', 'duplicate "${opt.id}"');
        }
        options.add(opt);
      }
      for (final g in Gender.values) {
        if ((gender == null || gender == g) &&
            !options.any((o) => o.isFor(g))) {
          throw ConfigException('$at.options', 'no options for ${g.name}');
        }
      }
    } else if (f.containsKey('options')) {
      throw ConfigException('$at.options', 'only choice/multi have options');
    }

    // Country texts.
    LocalizedText? questionPick;
    if (input.isCountry) {
      questionPick = _text(f['question_pick'], '$at.question_pick');
    } else if (f.containsKey('question_pick')) {
      throw ConfigException('$at.question_pick', 'only for country questions');
    }

    // Bounds.
    int? min, max;
    if (input.hasBounds) {
      min = _int(f['min'], '$at.min');
      max = _int(f['max'], '$at.max');
      if (min >= max) {
        throw ConfigException('$at.min', 'min ($min) must be below max ($max)');
      }
    } else if (f.containsKey('min') || f.containsKey('max')) {
      throw ConfigException('$at.min', 'only number/range have min/max');
    }

    final suggest = <Gender, RangeOffset>{};
    if (f.containsKey('suggest')) {
      if (input != InputType.range) {
        throw ConfigException('$at.suggest', 'only range questions');
      }
      final s = _object(f['suggest'], '$at.suggest');
      for (final MapEntry(:key, :value) in s.entries) {
        final g = _enum<Gender>(
          Gender.values,
          key,
          '$at.suggest.$key',
          (e) => e.name,
        );
        final pair = _list(value, '$at.suggest.$key');
        if (pair.length != 2) {
          throw ConfigException('$at.suggest.$key', 'expected [low, high]');
        }
        final low = _int(pair[0], '$at.suggest.$key[0]');
        final high = _int(pair[1], '$at.suggest.$key[1]');
        if (low > high) {
          throw ConfigException('$at.suggest.$key', 'low must be <= high');
        }
        suggest[g] = (low: low, high: high);
      }
    }

    // Multi-select extras.
    int? maxPick;
    var allowText = false;
    if (input == InputType.multi) {
      if (f['max_pick'] != null) {
        maxPick = _int(f['max_pick'], '$at.max_pick');
        if (maxPick < 1 || maxPick > options.length) {
          throw ConfigException(
            '$at.max_pick',
            'must be between 1 and the number of options (${options.length})',
          );
        }
      }
      allowText = _bool(f['allow_text'], '$at.allow_text');
    } else if (f.containsKey('max_pick') || f.containsKey('allow_text')) {
      throw ConfigException('$at.max_pick', 'only multi questions');
    }

    // Condition and fallbacks.
    Condition? condition;
    String? elseValue, elseFrom;
    if (f['if'] != null) {
      condition = _condition(f['if'], '$at.if', earlier);
      if (f['else_value'] != null && f['else_from'] != null) {
        throw ConfigException('$at.else_value', 'use else_value OR else_from');
      }
      if (f['else_value'] != null) {
        elseValue = _string(f['else_value'], '$at.else_value');
        if (!options.any((o) => o.id == elseValue)) {
          throw ConfigException(
            '$at.else_value',
            '"$elseValue" is not one of this question\'s option ids',
          );
        }
      }
      if (f['else_from'] != null) {
        elseFrom = _string(f['else_from'], '$at.else_from');
        if (!earlier.any((e) => e.key == elseFrom)) {
          throw ConfigException(
            '$at.else_from',
            '"$elseFrom" must be an earlier question',
          );
        }
      }
    } else if (f.containsKey('else_value') || f.containsKey('else_from')) {
      throw ConfigException('$at.else_value', 'needs an "if" condition');
    }

    final needsReview = <AppLanguage>{};
    if (f['needs_review'] != null) {
      final list = _list(f['needs_review'], '$at.needs_review');
      for (var i = 0; i < list.length; i++) {
        needsReview.add(
          _enum<AppLanguage>(
            AppLanguage.values,
            list[i],
            '$at.needs_review[$i]',
            (e) => e.code,
          ),
        );
      }
    }

    return FieldDef(
      key: key,
      chapter: chapter,
      input: input,
      visibility: visibility,
      question: _text(f['question'], '$at.question'),
      why: _text(f['why'], '$at.why'),
      questionPick: questionPick,
      invalid: f['invalid'] == null ? null : _text(f['invalid'], '$at.invalid'),
      options: List.unmodifiable(options),
      gender: gender,
      condition: condition,
      elseValue: elseValue,
      elseFrom: elseFrom,
      optional: _bool(f['optional'], '$at.optional'),
      min: min,
      max: max,
      suggest: Map.unmodifiable(suggest),
      maxPick: maxPick,
      allowText: allowText,
      needsReview: Set.unmodifiable(needsReview),
    );
  }

  OptionDef _option(Object? json, String path) {
    final o = _object(json, path);
    _checkProperties(o, _optionProperties, path);
    return OptionDef(
      id: _string(o['id'], '$path.id'),
      label: _text(o['label'], '$path.label'),
      gender: o['gender'] == null
          ? null
          : _enum<Gender>(
              Gender.values,
              o['gender'],
              '$path.gender',
              (e) => e.name,
            ),
    );
  }

  Condition _condition(Object? json, String path, List<FieldDef> earlier) {
    final c = _object(json, path);
    _checkProperties(c, const {'field', 'in', 'not_in'}, path);
    final ref = _string(c['field'], '$path.field');
    final target = earlier.where((e) => e.key == ref).firstOrNull;
    if (target == null) {
      throw ConfigException(
        '$path.field',
        '"$ref" must be an earlier question',
      );
    }
    if (target.input != InputType.choice) {
      throw ConfigException('$path.field', '"$ref" must be a choice question');
    }
    final hasIn = c.containsKey('in'), hasNotIn = c.containsKey('not_in');
    if (hasIn == hasNotIn) {
      throw ConfigException(path, 'use exactly one of "in" / "not_in"');
    }
    final mode = hasIn ? 'in' : 'not_in';
    final ids = _list(c[mode], '$path.$mode', nonEmpty: true);
    final set = <String>{};
    for (var i = 0; i < ids.length; i++) {
      final id = _string(ids[i], '$path.$mode[$i]');
      if (target.option(id) == null) {
        throw ConfigException(
          '$path.$mode[$i]',
          '"$id" is not an option of "$ref"',
        );
      }
      set.add(id);
    }
    return Condition(field: ref, optionIds: set, negate: !hasIn);
  }

  ScriptTexts _script(Object? json) {
    final s = _object(json, 'script');
    _checkProperties(s, _scriptProperties, 'script');
    return ScriptTexts(
      greeting: _text(s['greeting'], 'script.greeting'),
      acks: _textList(s['acks'], 'script.acks'),
      nameAck: _text(s['name_ack'], 'script.name_ack'),
      selfIntro: _text(s['self_intro'], 'script.self_intro'),
      analysing: _text(s['analysing'], 'script.analysing'),
    );
  }

  // --- texts -----------------------------------------------------------------

  /// A text: `{"en": ..., "ar": ...}`, each a string or
  /// `{"male": ..., "female": ...}`. Checks for missing versions and unknown
  /// placeholders.
  LocalizedText _text(Object? json, String path) {
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

  GenderedText _language(Object? json, String path) {
    if (json is String) return GenderedText.same(_plainText(json, path));
    if (json is Map) {
      for (final key in json.keys) {
        if (key != 'male' && key != 'female') {
          throw ConfigException('$path.$key', 'use "male" and "female" only');
        }
      }
      return GenderedText(
        _plainText(json['male'], '$path.male'),
        _plainText(json['female'], '$path.female'),
      );
    }
    throw ConfigException(path, 'missing text');
  }

  String _plainText(Object? json, String path) {
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

  LocalizedTextList _textList(Object? json, String path) {
    if (json is! Map) {
      throw ConfigException(path, 'expected {"en": [...], "ar": [...]}');
    }
    List<String> lang(String code) {
      final list = json[code];
      if (list is! List || list.isEmpty) {
        throw ConfigException('$path.$code', 'expected a non-empty list');
      }
      return [
        for (var i = 0; i < list.length; i++)
          _plainText(list[i], '$path.$code[$i]'),
      ];
    }

    return LocalizedTextList(en: lang('en'), ar: lang('ar'));
  }

  // --- small typed readers -------------------------------------------------

  /// Rejects misspelled property names (keys starting with `_` are comments).
  void _checkProperties(Map<String, Object?> m, Set<String> allowed, String p) {
    for (final key in m.keys) {
      if (!key.startsWith('_') && !allowed.contains(key)) {
        throw ConfigException('$p.$key', 'unknown property "$key"');
      }
    }
  }

  Map<String, Object?> _object(Object? v, String path) {
    if (v is! Map) throw ConfigException(path, 'expected an object');
    return Map<String, Object?>.from(v);
  }

  List<Object?> _list(Object? v, String path, {bool nonEmpty = false}) {
    if (v is! List) throw ConfigException(path, 'expected a list');
    if (nonEmpty && v.isEmpty) throw ConfigException(path, 'must not be empty');
    return v;
  }

  String _string(Object? v, String path) {
    if (v is! String || v.isEmpty) {
      throw ConfigException(path, 'expected text');
    }
    return v;
  }

  int _int(Object? v, String path) {
    if (v is! int) throw ConfigException(path, 'expected a whole number');
    return v;
  }

  bool _bool(Object? v, String path) {
    if (v == null) return false;
    if (v is! bool) throw ConfigException(path, 'expected true or false');
    return v;
  }

  T _enum<T>(List<T> values, Object? v, String path, String Function(T) name) {
    for (final value in values) {
      if (name(value) == v) return value;
    }
    throw ConfigException(
      path,
      'expected one of ${values.map(name).join(', ')}, got $v',
    );
  }
}
