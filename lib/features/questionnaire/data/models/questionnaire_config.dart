import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/config_exception.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/localized_text.dart';

/// How a question is answered.
enum InputType {
  text('text'),
  number('number'),
  range('range'),
  choice('choice'),
  multi('multi'),
  country('country'),
  countryOptional('country_optional');

  const InputType(this.jsonName);
  final String jsonName;

  bool get hasOptions => this == choice || this == multi;
  bool get isCountry => this == country || this == countryOptional;
  bool get hasBounds => this == number || this == range;
}

/// Who may see an answer.
enum FieldVisibility {
  /// Shown to matches on the profile card.
  card,

  /// Private: used by Khalty for matching, never shown on the card.
  khalty,
}

/// One chapter of the questionnaire.
class ChapterDef {
  const ChapterDef({required this.id, required this.title, this.intro});

  final int id;
  final LocalizedText title;

  /// Khalty's line before the chapter's first question.
  final LocalizedText? intro;
}

/// One possible answer to a choice/multi question.
class OptionDef {
  const OptionDef({required this.id, required this.label, this.gender});

  /// Saved in users' answers; never changes once live.
  final String id;
  final LocalizedText label;

  /// Shown only to this gender, when set.
  final Gender? gender;

  bool isFor(Gender g) => gender == null || gender == g;
}

/// "Ask only if an earlier answer is (not) one of these options."
class Condition {
  const Condition({
    required this.field,
    required this.optionIds,
    required this.negate,
  });

  final String field;
  final Set<String> optionIds;

  /// True for `not_in`, false for `in`.
  final bool negate;

  bool isMetBy(String optionId) => optionIds.contains(optionId) != negate;
}

/// Where the partner-age slider starts, relative to the user's age.
typedef RangeOffset = ({int low, int high});

/// One question.
class FieldDef {
  const FieldDef({
    required this.key,
    required this.chapter,
    required this.input,
    required this.visibility,
    required this.question,
    required this.why,
    this.questionPick,
    this.invalid,
    this.options = const [],
    this.gender,
    this.condition,
    this.elseValue,
    this.elseFrom,
    this.optional = false,
    this.min,
    this.max,
    this.suggest = const {},
    this.maxPick,
    this.allowText = false,
    this.needsReview = const {},
  });

  final String key;
  final int chapter;
  final InputType input;
  final FieldVisibility visibility;
  final LocalizedText question;
  final LocalizedText why;

  /// Country questions: the question shown with the country list.
  final LocalizedText? questionPick;

  /// Message for a typed answer that isn't valid.
  final LocalizedText? invalid;
  final List<OptionDef> options;

  /// Asked only to this gender, when set.
  final Gender? gender;
  final Condition? condition;

  /// Option id assumed when [condition] isn't met.
  final String? elseValue;

  /// Field whose answer is used when [condition] isn't met.
  final String? elseFrom;

  /// Shows a Skip button.
  final bool optional;
  final int? min;
  final int? max;
  final Map<Gender, RangeOffset> suggest;
  final int? maxPick;
  final bool allowText;

  /// Languages whose texts still need native review.
  final Set<AppLanguage> needsReview;

  bool isAskedTo(Gender g) => gender == null || gender == g;

  /// The options this user may pick from, in order.
  List<OptionDef> optionsFor(Gender g) => [
    for (final o in options)
      if (o.isFor(g)) o,
  ];

  OptionDef? option(String id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }
}

/// Khalty's lines during the questionnaire.
class ScriptTexts {
  const ScriptTexts({
    required this.greeting,
    required this.acks,
    required this.nameAck,
    required this.selfIntro,
    required this.analysing,
  });

  final LocalizedText greeting;
  final LocalizedTextList acks;
  final LocalizedText nameAck;
  final LocalizedText selfIntro;
  final LocalizedText analysing;
}

/// The whole questionnaire, parsed and checked.
class QuestionnaireConfig {
  QuestionnaireConfig._({
    required this.chapters,
    required this.fields,
    required this.script,
  }) : _byKey = {for (final f in fields) f.key: f};

  /// Parses and checks the config; throws [ConfigException] naming the exact
  /// place of the first problem found.
  factory QuestionnaireConfig.fromJson(Object? json) =>
      _ConfigParser().parse(json);

  static const supportedSchemaVersion = 2;

  final List<ChapterDef> chapters;
  final List<FieldDef> fields;
  final ScriptTexts script;
  final Map<String, FieldDef> _byKey;

  FieldDef? field(String key) => _byKey[key];

  ChapterDef chapter(int id) => chapters.firstWhere((c) => c.id == id);
}

// ---------------------------------------------------------------------------
// Parsing and checks.

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

class _ConfigParser {
  QuestionnaireConfig parse(Object? json) {
    final root = _object(json, r'$');
    _checkProperties(root, _rootProperties, r'$');

    final version = root['schema_version'];
    if (version != QuestionnaireConfig.supportedSchemaVersion) {
      throw ConfigException(
        'schema_version',
        'expected ${QuestionnaireConfig.supportedSchemaVersion}, got $version',
      );
    }

    final chapters = _chapters(root['chapters']);
    final chapterIds = {for (final c in chapters) c.id};

    final fieldsJson = _list(root['fields'], 'fields', nonEmpty: true);
    final fields = <FieldDef>[];
    for (var i = 0; i < fieldsJson.length; i++) {
      fields.add(_field(fieldsJson[i], 'fields[$i]', chapterIds, fields));
    }

    return QuestionnaireConfig._(
      chapters: List.unmodifiable(chapters),
      fields: List.unmodifiable(fields),
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
          title: LocalizedText.fromJson(c['title'], '$path.title'),
          intro: c['intro'] == null
              ? null
              : LocalizedText.fromJson(c['intro'], '$path.intro'),
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
      (e) => e.jsonName,
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
      questionPick = LocalizedText.fromJson(
        f['question_pick'],
        '$at.question_pick',
      );
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
      question: LocalizedText.fromJson(f['question'], '$at.question'),
      why: LocalizedText.fromJson(f['why'], '$at.why'),
      questionPick: questionPick,
      invalid: f['invalid'] == null
          ? null
          : LocalizedText.fromJson(f['invalid'], '$at.invalid'),
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
      label: LocalizedText.fromJson(o['label'], '$path.label'),
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
      greeting: LocalizedText.fromJson(s['greeting'], 'script.greeting'),
      acks: LocalizedTextList.fromJson(s['acks'], 'script.acks'),
      nameAck: LocalizedText.fromJson(s['name_ack'], 'script.name_ack'),
      selfIntro: LocalizedText.fromJson(s['self_intro'], 'script.self_intro'),
      analysing: LocalizedText.fromJson(s['analysing'], 'script.analysing'),
    );
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
