import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/localized_text.dart';

/// How a question is answered.
enum InputType {
  text,
  number,
  range,
  choice,
  multi,
  country,
  countryOptional;

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

/// The whole questionnaire. Built by the data layer's parser, which
/// guarantees it is consistent (see `QuestionnaireConfigParser`).
class QuestionnaireConfig {
  QuestionnaireConfig({
    required List<ChapterDef> chapters,
    required List<FieldDef> fields,
    required this.script,
  }) : chapters = List.unmodifiable(chapters),
       fields = List.unmodifiable(fields),
       _byKey = {for (final f in fields) f.key: f};

  final List<ChapterDef> chapters;
  final List<FieldDef> fields;
  final ScriptTexts script;
  final Map<String, FieldDef> _byKey;

  FieldDef? field(String key) => _byKey[key];

  ChapterDef chapter(int id) => chapters.firstWhere((c) => c.id == id);
}
