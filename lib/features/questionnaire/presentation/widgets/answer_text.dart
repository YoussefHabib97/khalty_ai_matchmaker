import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// An answer as the user reads it: option labels in the app language and
/// the user's gender, country names, "29–38" for ranges. [field] is the
/// field whose options describe [value] (for derived answers, the source
/// field). Null for an answer that shouldn't be shown (not applicable).
String? answerText(
  AppLocalizations l10n,
  AppLanguage language,
  Gender gender,
  FieldDef field,
  AnswerValue value,
) {
  String label(String id) =>
      field.option(id)?.label.resolve(language, gender) ?? id;
  return switch (value) {
    TextAnswer(:final text) => text,
    NumberAnswer(value: final n) => '$n',
    ChoiceAnswer(:final optionId) => label(optionId),
    MultiAnswer(:final optionIds, :final custom) => [
      ...optionIds.map(label),
      ...custom,
    ].join(language == AppLanguage.ar ? '، ' : ', '),
    RangeAnswer(:final min, :final max) => l10n.rangeYears(min, max),
    CountryAnswer(:final iso2) => countryByIso(iso2)?.name(language) ?? iso2,
    NoneAnswer() => l10n.answerNo,
    SkippedAnswer() => l10n.answerSkipped,
    NotApplicable() => null,
  };
}
