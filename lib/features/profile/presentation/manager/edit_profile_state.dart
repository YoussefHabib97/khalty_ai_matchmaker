import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// One answered question in the edit list.
class EditRow {
  const EditRow({
    required this.field,
    required this.value,
    required this.source,
  });

  final FieldDef field;

  /// The effective answer (null when it applies but isn't answered).
  final AnswerValue? value;

  /// The field whose options describe [value] (differs for derived answers).
  final FieldDef source;
}

/// A chapter's questions in the edit list.
class EditSection {
  const EditSection({required this.chapter, required this.rows});

  final ChapterDef chapter;
  final List<EditRow> rows;
}

/// Everything the edit-profile screen shows.
class EditProfileState {
  const EditProfileState({
    this.profile,
    this.sections = const [],
    this.pending,
    this.followUp,
    this.invalid,
    this.answersChanged = false,
    this.busy = false,
    this.refreshingBrief = false,
    this.photoFailed = false,
  });

  /// Null only when signed out meanwhile (the router is leaving).
  final UserProfile? profile;

  /// Questions that apply, by chapter, with their answers.
  final List<EditSection> sections;

  /// An edit that made other questions apply; saved only once those are
  /// answered too (see [followUp]), so the profile never has gaps.
  final Answers? pending;

  /// The next question that now applies because of [pending].
  final FieldDef? followUp;

  /// Why the answer in the open sheet was rejected.
  final InvalidReason? invalid;

  /// An answer was saved: the brief is refreshed when leaving.
  final bool answersChanged;

  /// Saving a photo or a setting.
  final bool busy;
  final bool refreshingBrief;
  final bool photoFailed;

  /// The answers to edit from (including [pending] ones).
  Answers get answers => pending ?? profile?.answers ?? Answers();

  EditProfileState copyWith({
    UserProfile? profile,
    List<EditSection>? sections,
    Object? pending = _unset,
    Object? followUp = _unset,
    Object? invalid = _unset,
    bool? answersChanged,
    bool? busy,
    bool? refreshingBrief,
    bool? photoFailed,
  }) => EditProfileState(
    profile: profile ?? this.profile,
    sections: sections ?? this.sections,
    pending: identical(pending, _unset) ? this.pending : pending as Answers?,
    followUp: identical(followUp, _unset)
        ? this.followUp
        : followUp as FieldDef?,
    invalid: identical(invalid, _unset)
        ? this.invalid
        : invalid as InvalidReason?,
    answersChanged: answersChanged ?? this.answersChanged,
    busy: busy ?? this.busy,
    refreshingBrief: refreshingBrief ?? this.refreshingBrief,
    photoFailed: photoFailed ?? this.photoFailed,
  );
}

const _unset = Object();
