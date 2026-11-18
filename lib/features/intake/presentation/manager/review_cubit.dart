import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';

/// ViewModel for "What I understood": **That's me** finishes onboarding;
/// **Rewrite my introduction** clears the analysis so the session goes back
/// to the self-introduction (which starts from the earlier text).
class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit({required ProfileRepository profiles, DateTime Function()? now})
    : _profiles = profiles,
      _now = now ?? DateTime.now,
      super(
        ReviewState(
          gender: profiles.current?.gender ?? Gender.female,
          analysis: profiles.current?.analysis,
          name: profiles.current?.name,
        ),
      );

  final ProfileRepository _profiles;
  final DateTime Function() _now;

  /// "That's me".
  Future<void> confirm() => _save(
    (p) => p.copyWith(progress: p.progress.copyWith(confirmedAt: _now())),
  );

  /// Edit → "Rewrite my introduction".
  Future<void> rewriteIntroduction() => _save(
    (p) => p.copyWith(
      analysis: null,
      progress: p.progress.copyWith(selfIntroDoneAt: null),
    ),
  );

  Future<void> _save(UserProfile Function(UserProfile) change) async {
    final profile = _profiles.current;
    if (profile == null || state.isSaving) return;
    _emit(state.copyWith(isSaving: true, saveFailed: false));
    try {
      await _profiles.save(change(profile));
    } on Exception {
      _emit(state.copyWith(isSaving: false, saveFailed: true));
      return;
    }
    // Stay "saving": the session is about to leave this screen.
  }

  void _emit(ReviewState next) {
    if (!isClosed) emit(next);
  }
}
