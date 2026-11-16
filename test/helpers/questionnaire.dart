import 'dart:convert';
import 'dart:io';

import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config_parser.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

export 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_autofill.dart';

/// The real bundled questionnaire, read from disk (no Flutter binding needed).
QuestionnaireConfig loadRealConfig() => const QuestionnaireConfigParser().parse(
  jsonDecode(File(AssetQuestionnaireRepository.assetPath).readAsStringSync()),
);
