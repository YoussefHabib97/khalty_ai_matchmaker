import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// Where the questionnaire comes from. Today: the bundled asset. Later it
/// could come from Firebase Remote Config without changing callers.
abstract interface class QuestionnaireRepository {
  /// Loads the questionnaire. Implementations throw if it is invalid.
  Future<QuestionnaireConfig> load();
}
