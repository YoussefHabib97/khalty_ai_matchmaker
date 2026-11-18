import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';

/// Everything the review screen shows.
class ReviewState {
  const ReviewState({
    required this.gender,
    this.analysis,
    this.name,
    this.isSaving = false,
    this.saveFailed = false,
  });

  final Gender gender;

  /// Null only when signed out meanwhile (the router is leaving).
  final IntakeAnalysis? analysis;
  final String? name;
  final bool isSaving;
  final bool saveFailed;

  ReviewState copyWith({bool? isSaving, bool? saveFailed}) => ReviewState(
    gender: gender,
    analysis: analysis,
    name: name,
    isSaving: isSaving ?? this.isSaving,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}
