import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config_parser.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/repos/questionnaire_repository.dart';

/// Loads the questionnaire bundled with the app. Throws `ConfigException`
/// if the file is invalid.
class AssetQuestionnaireRepository implements QuestionnaireRepository {
  AssetQuestionnaireRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/config/questionnaire.json';

  final AssetBundle _bundle;
  final _parser = const QuestionnaireConfigParser();

  @override
  Future<QuestionnaireConfig> load() async {
    final raw = await _bundle.loadString(assetPath);
    return _parser.parse(jsonDecode(raw));
  }
}
