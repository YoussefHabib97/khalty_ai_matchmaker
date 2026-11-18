import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// What the questionnaire screen is showing.
sealed class IntakeStep {
  const IntakeStep();
}

/// Khalty's greeting before the very first question.
final class GreetingStep extends IntakeStep {
  const GreetingStep(this.next);

  /// The question shown after the greeting.
  final FieldDef next;

  @override
  bool operator ==(Object other) =>
      other is GreetingStep && other.next.key == next.key;
  @override
  int get hashCode => Object.hash(GreetingStep, next.key);
}

/// Khalty's line before a chapter's first question.
final class ChapterIntroStep extends IntakeStep {
  const ChapterIntroStep(this.chapter, this.next);

  final ChapterDef chapter;

  /// The chapter's first question, shown after the intro.
  final FieldDef next;

  @override
  bool operator ==(Object other) =>
      other is ChapterIntroStep &&
      other.chapter.id == chapter.id &&
      other.next.key == next.key;
  @override
  int get hashCode => Object.hash(ChapterIntroStep, chapter.id, next.key);
}

/// One question.
final class QuestionStep extends IntakeStep {
  const QuestionStep(this.field);

  final FieldDef field;

  @override
  bool operator ==(Object other) =>
      other is QuestionStep && other.field.key == field.key;
  @override
  int get hashCode => Object.hash(QuestionStep, field.key);
}

/// Every question is answered; the app moves on to the self-introduction.
final class DoneStep extends IntakeStep {
  const DoneStep();

  @override
  bool operator ==(Object other) => other is DoneStep;
  @override
  int get hashCode => (DoneStep).hashCode;
}

/// Khalty's short reply to the previous answer, shown above the question.
/// The view turns it into text from the config's script.
sealed class IntakeReply {
  const IntakeReply();
}

/// "Nice to meet you, {name}!" after the name question.
final class NameReply extends IntakeReply {
  const NameReply();

  @override
  bool operator ==(Object other) => other is NameReply;
  @override
  int get hashCode => (NameReply).hashCode;
}

/// One of the general replies ("Lovely.", "Noted 🌸"…), in turn.
final class GeneralReply extends IntakeReply {
  const GeneralReply(this.index);

  /// Which reply; wraps around the config's list.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is GeneralReply && other.index == index;
  @override
  int get hashCode => Object.hash(GeneralReply, index);
}

/// Everything the questionnaire screen shows.
class IntakeState {
  const IntakeState({
    required this.step,
    required this.answers,
    required this.progress,
    required this.gender,
    required this.config,
    this.suggestedCountry,
    this.suggestedRange,
    this.reply,
    this.invalid,
    this.saveFailed = false,
    this.isSaving = false,
  });

  final IntakeStep step;

  /// The answers given so far (also the saved ones).
  final Answers answers;
  final QuestionnaireProgress progress;

  /// The user's gender: picks the gendered version of every config text.
  final Gender gender;

  /// The questionnaire: chapters and Khalty's lines (greeting, replies).
  final QuestionnaireConfig config;

  /// Country questions: the country to confirm (ISO code): the earlier
  /// answer, else the country of residence (nationality) or the phone's
  /// country. Fills `{detected}` / `{residence}` in the question.
  final String? suggestedCountry;

  /// Range questions: where the slider starts: the earlier answer, else
  /// around the user's age.
  final RangeAnswer? suggestedRange;

  /// Shown on a question reached by answering the previous one.
  final IntakeReply? reply;

  /// Why the last answer was rejected.
  final InvalidReason? invalid;

  /// The last answer couldn't be saved.
  final bool saveFailed;
  final bool isSaving;

  /// False on the greeting: Back there leaves the app.
  bool get canGoBack => step is QuestionStep || step is ChapterIntroStep;

  /// The user's name once answered, for `{name}` in Khalty's texts.
  String? get name => switch (answers[FieldKeys.name]) {
    TextAnswer(:final text) => text,
    _ => null,
  };

  IntakeState copyWith({
    bool? saveFailed,
    bool? isSaving,
    Object? invalid = _unset,
  }) => IntakeState(
    step: step,
    answers: answers,
    progress: progress,
    gender: gender,
    config: config,
    suggestedCountry: suggestedCountry,
    suggestedRange: suggestedRange,
    reply: reply,
    invalid: identical(invalid, _unset)
        ? this.invalid
        : invalid as InvalidReason?,
    saveFailed: saveFailed ?? this.saveFailed,
    isSaving: isSaving ?? this.isSaving,
  );
}

const _unset = Object();
