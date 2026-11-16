import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// Fills in the questionnaire with simple valid answers. For tests and the
/// debug stage panel only — never for real users.
abstract final class QuestionnaireAutofill {
  /// A simple valid answer for [field]: first option, minimum number (age
  /// 30), the suggested range, Saudi Arabia, "no second nationality", etc.
  static AnswerValue defaultAnswer(
    QuestionnaireEngine engine,
    FieldDef field,
    Answers answers,
  ) => switch (field.input) {
    InputType.text => TextAnswer(field.key == 'name' ? 'Sara' : 'Something'),
    InputType.number => NumberAnswer(field.key == 'age' ? 30 : field.min!),
    InputType.range =>
      engine.suggestedRange(field.key, answers) ??
          RangeAnswer(field.min!, field.max!),
    InputType.choice => ChoiceAnswer(field.optionsFor(engine.gender).first.id),
    InputType.multi => MultiAnswer([field.optionsFor(engine.gender).first.id]),
    InputType.country => CountryAnswer('SA'),
    InputType.countryOptional => const NoneAnswer(),
  };

  /// Answers every remaining question in order, using [overrides] where
  /// given and [defaultAnswer] otherwise. [onStep] sees each intermediate
  /// state.
  static Answers answerAll(
    QuestionnaireEngine engine, {
    Answers? start,
    Map<String, AnswerValue> overrides = const {},
    void Function(Answers answers)? onStep,
  }) {
    var answers = start ?? Answers();
    for (
      var field = engine.nextField(answers);
      field != null;
      field = engine.nextField(answers)
    ) {
      final value =
          overrides[field.key] ?? defaultAnswer(engine, field, answers);
      answers = engine.apply(answers, field.key, value);
      onStep?.call(answers);
    }
    return answers;
  }
}
