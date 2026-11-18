import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_card_builder.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/profile_preview_state.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// ViewModel for "See how Khalty presents you": the user's own card as a
/// suggested match sees it, in English or Arabic.
class ProfilePreviewCubit extends Cubit<ProfilePreviewState> {
  ProfilePreviewCubit({
    required ProfileRepository profiles,
    required this._photos,
    required this._engineFor,
  }) : super(const ProfilePreviewState()) {
    _show(profiles.current);
    _subscription = profiles.watch().listen(_show);
  }

  final PhotoRepository _photos;
  final QuestionnaireEngine Function(Gender gender) _engineFor;
  late final StreamSubscription<UserProfile?> _subscription;

  /// Shows the card in [language].
  void showIn(AppLanguage language) => emit(state.copyWith(language: language));

  void _show(UserProfile? profile) {
    if (isClosed) return;
    if (profile == null) {
      emit(ProfilePreviewState(language: state.language));
      return;
    }
    final card = ProfileCardBuilder.of(profile, _engineFor(profile.gender));
    emit(
      ProfilePreviewState(
        card: card,
        photoPath: switch (card.photo) {
          final photo? => _photos.pathOf(photo),
          null => null,
        },
        language: state.language,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
