import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';

/// The outcome of Khalty's end-of-questionnaire analysis.
sealed class IntakeAnalysisResult {
  const IntakeAnalysisResult();
}

/// The introduction says too little about the user (off-topic, a joke,
/// one word…). Khalty asks once for more; nothing is analysed.
final class IntroNeedsMore extends IntakeAnalysisResult {
  const IntroNeedsMore(this.reply);

  /// Khalty's kind request, saying what would help.
  final String reply;
}

/// The analysis is ready.
final class IntakeAnalysed extends IntakeAnalysisResult {
  const IntakeAnalysed(this.analysis);

  final IntakeAnalysis analysis;
}

/// Khalty's AI couldn't answer (network, quota, malformed output…).
class KhaltyAiException implements Exception {
  const KhaltyAiException(this.message);

  final String message;

  @override
  String toString() => 'KhaltyAiException: $message';
}
