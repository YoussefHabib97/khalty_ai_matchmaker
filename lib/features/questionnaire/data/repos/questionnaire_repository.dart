import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config.dart';

/// Where the questionnaire comes from. Today: the bundled asset. Later it
/// could come from Firebase Remote Config without changing callers.
abstract interface class QuestionnaireRepository {
  /// Loads and checks the questionnaire; throws `ConfigException` if invalid.
  Future<QuestionnaireConfig> load();
}

class AssetQuestionnaireRepository implements QuestionnaireRepository {
  AssetQuestionnaireRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/config/questionnaire.json';

  final AssetBundle _bundle;

  @override
  Future<QuestionnaireConfig> load() async {
    final raw = await _bundle.loadString(assetPath);
    return QuestionnaireConfig.fromJson(jsonDecode(raw));
  }
}
