import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// The message for an answer the engine rejected. A question's own `invalid`
/// text from the config (e.g. "Please type your age as a number between 18
/// and 80…") wins for typed numbers; otherwise a general message.
String invalidAnswerText(
  AppLocalizations l10n,
  AppLanguage language,
  Gender gender,
  FieldDef field,
  InvalidReason reason,
) {
  const numberProblems = {
    InvalidReason.empty,
    InvalidReason.wrongType,
    InvalidReason.outOfRange,
  };
  if (field.invalid case final text? when numberProblems.contains(reason)) {
    return text.resolve(language, gender);
  }
  return switch (reason) {
    InvalidReason.empty => l10n.answerRequired,
    InvalidReason.tooLong => l10n.answerTooLong(
      QuestionnaireEngine.maxTextLength,
    ),
    InvalidReason.invalidName => l10n.answerLettersOnly,
    InvalidReason.outOfRange when field.min != null && field.max != null =>
      l10n.answerNumberBetween(field.min!, field.max!),
    InvalidReason.wrongType when field.input == InputType.number =>
      l10n.answerNumberRequired,
    _ => l10n.answerInvalid,
  };
}
