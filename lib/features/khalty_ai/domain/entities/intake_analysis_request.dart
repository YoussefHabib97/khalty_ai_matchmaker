import 'package:khalty_ai_matchmaker/core/constants/enums.dart';

/// What Khalty's end-of-questionnaire analysis is given.
class IntakeAnalysisRequest {
  IntakeAnalysisRequest({
    required this.gender,
    required this.language,
    required this.name,
    required Map<String, Object> answers,
    this.introduction,
    this.mustAccept = false,
  }) : answers = Map.unmodifiable(answers);

  final Gender gender;

  /// The language to write in (the app language).
  final AppLanguage language;
  final String name;

  /// The effective answers with English labels, as made by
  /// `QuestionnaireEngine.toAiPayload`.
  final Map<String, Object> answers;

  /// The self-introduction; null when skipped.
  final String? introduction;

  /// The user was already asked once for more: accept what they wrote.
  final bool mustAccept;
}
