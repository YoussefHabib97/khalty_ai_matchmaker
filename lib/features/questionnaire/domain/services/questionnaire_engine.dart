import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/text_validators.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// Whether a field is asked, given the answers so far.
enum _Status {
  applies,
  doesNotApply,

  /// Its condition depends on an answer not given yet.
  unknown,
}

/// The questionnaire's rules, for one user: which question comes next, which
/// questions apply, what derived answers are, whether an answer is valid, and
/// progress. Pure and stateless: every method takes the current [Answers].
/// Used by the intake flow and by profile editing alike.
class QuestionnaireEngine {
  QuestionnaireEngine(this.config, this.gender)
    : fields = List.unmodifiable([
        for (final f in config.fields)
          if (f.isAskedTo(gender)) f,
      ]);

  /// Longest free text accepted (names, cities, jobs, typed options).
  static const maxTextLength = 100;

  final QuestionnaireConfig config;
  final Gender gender;

  /// The questions this user is asked (gender-filtered), in order.
  final List<FieldDef> fields;

  // --- applicability and derived answers ------------------------------------

  /// Whether [field] is asked, given earlier answers.
  bool applies(FieldDef field, Answers answers) =>
      _status(field, answers) == _Status.applies;

  /// The answer to use for [key]: the user's (if it applies and is valid), or
  /// a derived value when the field doesn't apply. Null when the field
  /// applies but has no valid answer yet.
  EffectiveAnswer? effective(String key, Answers answers) {
    final field = _field(key);
    switch (_status(field, answers)) {
      case _Status.applies:
        final value = answers[key];
        if (value == null || !validate(field, value).isValid) return null;
        return EffectiveAnswer(value, sourceKey: key);
      case _Status.unknown:
        return null;
      case _Status.doesNotApply:
        if (field.elseValue case final id?) {
          return EffectiveAnswer(
            ChoiceAnswer(id),
            sourceKey: key,
            derived: true,
          );
        }
        if (field.elseFrom case final from?) {
          final source = effective(from, answers);
          if (source == null) return null;
          return EffectiveAnswer(
            source.value,
            sourceKey: source.sourceKey,
            derived: true,
          );
        }
        return EffectiveAnswer(
          const NotApplicable(),
          sourceKey: key,
          derived: true,
        );
    }
  }

  // --- navigation -----------------------------------------------------------

  /// The first question that applies and has no valid answer, or null when
  /// the questionnaire is complete. Also where to resume after a restart.
  FieldDef? nextField(Answers answers) {
    for (final field in fields) {
      if (applies(field, answers) && !_hasValidAnswer(field, answers)) {
        return field;
      }
    }
    return null;
  }

  /// For Back: the last applicable question before [beforeKey], or before
  /// the end when [beforeKey] is null. Null at the first question.
  FieldDef? previousField(String? beforeKey, Answers answers) {
    var end = fields.length;
    if (beforeKey != null) {
      end = fields.indexWhere((f) => f.key == beforeKey);
      if (end < 0) throw ArgumentError('"$beforeKey" is not asked to $gender');
    }
    for (var i = end - 1; i >= 0; i--) {
      if (applies(fields[i], answers)) return fields[i];
    }
    return null;
  }

  /// Questions that apply but have no valid answer (e.g. after an edit made
  /// a question apply again).
  List<FieldDef> missingAnswers(Answers answers) => [
    for (final field in fields)
      if (applies(field, answers) && !_hasValidAnswer(field, answers)) field,
  ];

  // --- validation -----------------------------------------------------------

  /// Whether [value] is an acceptable answer to [field] for this user.
  AnswerValidation validate(FieldDef field, AnswerValue value) {
    const valid = AnswerValidation.valid;
    if (value is SkippedAnswer) {
      return field.optional
          ? valid
          : const AnswerValidation.invalid(InvalidReason.notOptional);
    }
    final reason = switch ((field.input, value)) {
      (InputType.text, TextAnswer(:final text)) => _validateText(field, text),
      (InputType.number, NumberAnswer(value: final n)) =>
        _inBounds(field, n) ? null : InvalidReason.outOfRange,
      (InputType.range, RangeAnswer(:final min, :final max)) =>
        _inBounds(field, min) && _inBounds(field, max)
            ? null
            : InvalidReason.outOfRange,
      (InputType.choice, ChoiceAnswer(:final optionId)) =>
        _isOptionFor(field, optionId) ? null : InvalidReason.unknownOption,
      (InputType.multi, final MultiAnswer multi) => _validateMulti(
        field,
        multi,
      ),
      (InputType.country, CountryAnswer()) => null,
      (InputType.countryOptional, CountryAnswer() || NoneAnswer()) => null,
      _ => InvalidReason.wrongType,
    };
    return reason == null ? valid : AnswerValidation.invalid(reason);
  }

  /// Validates [value] and returns a copy of [answers] with it set (free text
  /// trimmed). Throws [InvalidAnswerException] if invalid.
  Answers apply(Answers answers, String key, AnswerValue value) {
    final field = _field(key);
    if (!field.isAskedTo(gender)) {
      throw ArgumentError('"$key" is not asked to $gender');
    }
    final normalized = switch (value) {
      TextAnswer(:final text) => TextAnswer(text.trim()),
      MultiAnswer(:final optionIds, :final custom) => MultiAnswer(
        optionIds,
        custom: [for (final c in custom) c.trim()],
      ),
      _ => value,
    };
    final result = validate(field, normalized);
    if (!result.isValid) throw InvalidAnswerException(key, result.reason!);
    return answers.set(key, normalized);
  }

  // --- progress and helpers for screens ---------------------------------------

  /// Answered vs total applicable questions, and the current chapter.
  /// Questions whose condition isn't known yet count as still to come, so the
  /// remaining count only goes down as the user moves forward.
  QuestionnaireProgress progress(Answers answers) {
    var answered = 0, total = 0;
    for (final field in fields) {
      switch (_status(field, answers)) {
        case _Status.applies:
          total++;
          if (_hasValidAnswer(field, answers)) answered++;
        case _Status.unknown:
          total++;
        case _Status.doesNotApply:
          break;
      }
    }
    return QuestionnaireProgress(
      answered: answered,
      total: total,
      chapter: nextField(answers)?.chapter ?? config.chapters.last.id,
      chapterCount: config.chapters.length,
    );
  }

  /// Where a range slider starts: the user's age plus the field's `suggest`
  /// offsets for their gender, kept within the field's bounds. Null if the
  /// age isn't known or the field has no suggestion.
  RangeAnswer? suggestedRange(String key, Answers answers) {
    final field = _field(key);
    final offset = field.suggest[gender];
    final age = switch (effective(FieldKeys.age, answers)?.value) {
      NumberAnswer(:final value) => value,
      _ => null,
    };
    if (offset == null || age == null) return null;
    int clamp(int v) => v.clamp(field.min!, field.max!);
    return RangeAnswer(clamp(age + offset.low), clamp(age + offset.high));
  }

  /// All effective answers in English, for the AI. Questions that don't apply
  /// or were skipped are left out. Countries stay as ISO codes for now.
  Map<String, Object> toAiPayload(Answers answers) {
    final payload = <String, Object>{};
    for (final field in fields) {
      final eff = effective(field.key, answers);
      if (eff == null) continue;
      String label(String id) =>
          _field(eff.sourceKey)
              .option(id)
              ?.label
              .resolve(AppLanguage.en, gender) ??
          id;
      final value = switch (eff.value) {
        TextAnswer(:final text) => text,
        NumberAnswer(:final value) => value,
        ChoiceAnswer(:final optionId) => label(optionId),
        MultiAnswer(:final optionIds, :final custom) => [
          ...optionIds.map(label),
          ...custom,
        ],
        RangeAnswer(:final min, :final max) => {'min': min, 'max': max},
        CountryAnswer(:final iso2) => iso2,
        NoneAnswer() => 'None',
        SkippedAnswer() || NotApplicable() => null,
      };
      if (value != null) payload[field.key] = value;
    }
    return payload;
  }

  // --- internals --------------------------------------------------------------

  FieldDef _field(String key) =>
      config.field(key) ?? (throw ArgumentError('Unknown field "$key"'));

  _Status _status(FieldDef field, Answers answers) {
    if (!field.isAskedTo(gender)) return _Status.doesNotApply;
    final condition = field.condition;
    if (condition == null) return _Status.applies;
    final ref = effective(condition.field, answers);
    if (ref == null) return _Status.unknown;
    return switch (ref.value) {
      ChoiceAnswer(:final optionId) when condition.isMetBy(optionId) =>
        _Status.applies,
      _ => _Status.doesNotApply,
    };
  }

  bool _hasValidAnswer(FieldDef field, Answers answers) {
    final value = answers[field.key];
    return value != null && validate(field, value).isValid;
  }

  bool _inBounds(FieldDef field, int n) =>
      (field.min == null || n >= field.min!) &&
      (field.max == null || n <= field.max!);

  bool _isOptionFor(FieldDef field, String id) =>
      field.option(id)?.isFor(gender) ?? false;

  InvalidReason? _validateText(FieldDef field, String raw) {
    final text = raw.trim();
    if (text.isEmpty) return InvalidReason.empty;
    if (text.length > maxTextLength) return InvalidReason.tooLong;
    if (field.key == FieldKeys.name && !isValidPersonName(text)) {
      return InvalidReason.invalidName;
    }
    return null;
  }

  InvalidReason? _validateMulti(FieldDef field, MultiAnswer multi) {
    if (multi.count == 0) return InvalidReason.empty;
    if (multi.optionIds.toSet().length != multi.optionIds.length) {
      return InvalidReason.duplicateOption;
    }
    if (!multi.optionIds.every((id) => _isOptionFor(field, id))) {
      return InvalidReason.unknownOption;
    }
    if (multi.custom.isNotEmpty) {
      if (!field.allowText) return InvalidReason.customNotAllowed;
      for (final entry in multi.custom) {
        final text = entry.trim();
        if (text.isEmpty) return InvalidReason.empty;
        if (text.length > maxTextLength) return InvalidReason.tooLong;
      }
    }
    if (field.maxPick case final max? when multi.count > max) {
      return InvalidReason.tooManyPicks;
    }
    return null;
  }
}
