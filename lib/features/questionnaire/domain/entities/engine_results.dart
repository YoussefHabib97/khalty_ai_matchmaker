import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';

/// The answer to use for a field: what the user gave, or a value derived from
/// the config when the field doesn't apply (`else_value`, `else_from`, or
/// [NotApplicable]). Derived values are computed, never stored.
class EffectiveAnswer {
  const EffectiveAnswer(
    this.value, {
    required this.sourceKey,
    this.derived = false,
  });

  final AnswerValue value;

  /// The field whose options describe [value]. Usually the field itself; for
  /// `else_from` it is the source field (e.g. `work` taken from `employment`).
  final String sourceKey;

  /// True when computed from the config rather than given by the user.
  final bool derived;

  @override
  bool operator ==(Object other) =>
      other is EffectiveAnswer &&
      other.value == value &&
      other.sourceKey == sourceKey &&
      other.derived == derived;
  @override
  int get hashCode => Object.hash(value, sourceKey, derived);
  @override
  String toString() =>
      'EffectiveAnswer($value, from: $sourceKey${derived ? ', derived' : ''})';
}

/// Why an answer was rejected. The UI turns each reason into a message.
enum InvalidReason {
  /// The answer type doesn't match the question's input.
  wrongType,

  /// Blank text, or a multi-select with nothing picked.
  empty,

  /// Text longer than allowed.
  tooLong,

  /// A name with characters other than letters, spaces and `,.'-`.
  invalidName,

  /// A number or range outside the question's min–max.
  outOfRange,

  /// An option id that doesn't exist for this user.
  unknownOption,

  /// The same option picked twice.
  duplicateOption,

  /// More picks than `max_pick`.
  tooManyPicks,

  /// Typed entries on a question that doesn't allow them.
  customNotAllowed,

  /// Skipped, but the question isn't optional.
  notOptional,
}

/// Result of validating an answer.
final class AnswerValidation {
  const AnswerValidation._(this.reason);
  const AnswerValidation.invalid(InvalidReason this.reason);

  static const valid = AnswerValidation._(null);

  /// Null when valid.
  final InvalidReason? reason;

  bool get isValid => reason == null;

  @override
  String toString() => isValid ? 'valid' : 'invalid($reason)';
}

/// Thrown by `QuestionnaireEngine.apply` for an invalid answer.
class InvalidAnswerException implements Exception {
  const InvalidAnswerException(this.fieldKey, this.reason);

  final String fieldKey;
  final InvalidReason reason;

  @override
  String toString() => 'Invalid answer for "$fieldKey": $reason';
}

/// How far through the questionnaire the user is.
class QuestionnaireProgress {
  const QuestionnaireProgress({
    required this.answered,
    required this.total,
    required this.chapter,
    required this.chapterCount,
  });

  /// Questions that apply and have a valid answer.
  final int answered;

  /// Questions that apply (including ones whose condition isn't known yet).
  final int total;

  /// The chapter of the next question (the last chapter when complete).
  final int chapter;
  final int chapterCount;

  int get remaining => total - answered;
  bool get isComplete => remaining == 0;

  /// 0.0–1.0.
  double get fraction => total == 0 ? 1 : answered / total;

  @override
  String toString() =>
      'QuestionnaireProgress($answered/$total, chapter $chapter/$chapterCount)';
}
