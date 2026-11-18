import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';

/// Khalty's AI. Today a fake; later Firebase AI Logic with the prompts in
/// `docs/ai_prompts.md`. Methods are added when a screen needs them (brief
/// refresh, classifying a typed answer, transcribing voice).
abstract interface class KhaltyAiRepository {
  /// The one AI step of onboarding: answers + self-introduction → bio,
  /// private impressions, brief, contradictions and a message to the user.
  /// May ask once for a better introduction ([IntroNeedsMore]). Throws
  /// [KhaltyAiException] when the AI can't answer.
  Future<IntakeAnalysisResult> analyseIntake(IntakeAnalysisRequest request);

  /// A new brief after the answers were edited (bio, impressions and
  /// contradictions are kept). [IntakeAnalysisRequest.mustAccept] is
  /// ignored. Throws [KhaltyAiException] when the AI can't answer.
  Future<String> refreshBrief(IntakeAnalysisRequest request);
}
