import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_completeness.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_state.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// ViewModel for the Me tab: the profile header (photo or silhouette, name,
/// "Khalty knows you X%"). Follows every profile change, so edits made
/// elsewhere show straight away.
class MeCubit extends Cubit<MeState> {
  MeCubit({
    required ProfileRepository profiles,
    required QuestionnaireEngine Function(Gender gender) engineFor,
  }) : _engineFor = engineFor,
       super(_stateFor(profiles.current, engineFor)) {
    _subscription = profiles.watch().listen(
      (profile) => emit(_stateFor(profile, _engineFor)),
    );
  }

  final QuestionnaireEngine Function(Gender) _engineFor;
  late final StreamSubscription<UserProfile?> _subscription;

  static MeState _stateFor(
    UserProfile? profile,
    QuestionnaireEngine Function(Gender) engineFor,
  ) {
    if (profile == null) return const MeState();
    final engine = engineFor(profile.gender);
    final answers = profile.answers;
    AnswerValue? effective(String key) => engine.effective(key, answers)?.value;

    final cover = effective(
      profile.gender == Gender.male ? FieldKeys.beard : FieldKeys.hijab,
    );
    return MeState(
      profile: profile,
      completeness: ProfileCompleteness.of(profile, engine),
      silhouette: SilhouetteStyle.of(
        profile.gender,
        cover is ChoiceAnswer ? cover.optionId : null,
      ),
      city: switch (effective(FieldKeys.city)) {
        TextAnswer(:final text) => text,
        _ => null,
      },
      countryIso: switch (effective(FieldKeys.country)) {
        CountryAnswer(:final iso2) => iso2,
        _ => null,
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
