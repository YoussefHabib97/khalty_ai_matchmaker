import 'dart:convert';
import 'dart:io';

import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config_parser.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// The real bundled questionnaire, read from disk (no Flutter binding needed).
QuestionnaireConfig loadRealConfig() => const QuestionnaireConfigParser().parse(
  jsonDecode(File(AssetQuestionnaireRepository.assetPath).readAsStringSync()),
);

/// A simple valid answer for [field]: first option, minimum number, the
/// suggested range, Saudi Arabia, "no second nationality", and so on.
AnswerValue defaultAnswer(
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

/// Answers every question in order, using [overrides] where given and
/// [defaultAnswer] otherwise. Optionally reports each step.
Answers fillAll(
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
    final value = overrides[field.key] ?? defaultAnswer(engine, field, answers);
    answers = engine.apply(answers, field.key, value);
    onStep?.call(answers);
  }
  return answers;
}
