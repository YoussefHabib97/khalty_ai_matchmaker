import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/contact_sanitizer.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/repos/khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_state.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// ViewModel for editing the profile: answers by chapter, About me, photos.
///
/// Answers are validated by the engine and saved straight away. When an
/// edit makes other questions apply (e.g. "Never married" → "Divorced"
/// brings back the children question), the edit is held as [pending] and
/// those questions are asked as follow-ups; everything is saved together
/// once they're answered, or dropped if the user cancels — so the profile
/// never has unanswered questions. Leaving refreshes Khalty's brief if any
/// answer changed.
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({
    required ProfileRepository profiles,
    required PhotoRepository photos,
    required KhaltyAiRepository ai,
    required QuestionnaireEngine Function(Gender gender) engineFor,
  }) : this._(
         profiles,
         photos,
         ai,
         engineFor(profiles.current?.gender ?? Gender.female),
       );

  EditProfileCubit._(this._profiles, this._photos, this._ai, this._engine)
    : super(const EditProfileState()) {
    _show(_profiles.current);
    _subscription = _profiles.watch().listen(_show);
  }

  final ProfileRepository _profiles;
  final PhotoRepository _photos;
  final KhaltyAiRepository _ai;
  final QuestionnaireEngine _engine;
  late final StreamSubscription<UserProfile?> _subscription;

  /// The user's gender (options and labels).
  Gender get gender => _engine.gender;

  /// The path to show [photo] from.
  String photoPath(ProfilePhoto photo) => _photos.pathOf(photo);

  // --- answers ----------------------------------------------------------------

  /// Country questions: the country to confirm in the editor.
  String? suggestedCountry(FieldDef field) {
    final answers = state.answers;
    if (answers[field.key] case CountryAnswer(:final iso2)) return iso2;
    if (field.key == FieldKeys.nationality) {
      if (_engine.effective(FieldKeys.country, answers)?.value
          case CountryAnswer(:final iso2)) {
        return iso2;
      }
    }
    return null;
  }

  /// Range questions: where the slider starts without an answer.
  RangeAnswer? suggestedRange(FieldDef field) =>
      _engine.suggestedRange(field.key, state.answers);

  /// Typed text or number. True when accepted (close the editor).
  Future<bool> saveTyped(FieldDef field, String raw) async {
    try {
      return await saveAnswer(field, _engine.parseTyped(field, raw));
    } on InvalidAnswerException catch (e) {
      _emit(state.copyWith(invalid: e.reason));
      return false;
    }
  }

  /// True when accepted (close the editor). Then check [EditProfileState.
  /// followUp] for a question that now applies.
  Future<bool> saveAnswer(FieldDef field, AnswerValue value) async {
    final Answers answers;
    try {
      answers = _engine.apply(state.answers, field.key, value);
    } on InvalidAnswerException catch (e) {
      _emit(state.copyWith(invalid: e.reason));
      return false;
    }
    final missing = _engine.missingAnswers(answers);
    if (missing.isNotEmpty) {
      _emit(
        state.copyWith(
          pending: answers,
          followUp: missing.first,
          invalid: null,
        ),
      );
      return true;
    }
    final profile = _profiles.current;
    if (profile == null) return false;
    await _profiles.save(profile.copyWith(answers: answers));
    _show(_profiles.current); // the list now, not when the stream delivers
    _emit(
      state.copyWith(
        pending: null,
        followUp: null,
        invalid: null,
        answersChanged: true,
      ),
    );
    return true;
  }

  /// The user closed a follow-up question: drop the whole pending edit.
  void cancelFollowUp() =>
      _emit(state.copyWith(pending: null, followUp: null, invalid: null));

  /// The editor's draft changed, or it closed: hide the error.
  void clearError() {
    if (state.invalid != null) _emit(state.copyWith(invalid: null));
  }

  // --- about me ------------------------------------------------------------------

  /// Saves the user's own bio with contact details removed. Returns true
  /// when something was removed (tell the user). An empty text hides
  /// Khalty's suggested bio.
  Future<bool> saveAboutMe(String text) async {
    final profile = _profiles.current;
    if (profile == null) return false;
    final clean = ContactInfoSanitizer.sanitize(text.trim());
    await _profiles.save(profile.copyWith(aboutMe: clean.text));
    return clean.removedSomething;
  }

  // --- photos --------------------------------------------------------------------

  Future<void> addPhoto(PhotoSource source) async {
    final profile = _profiles.current;
    if (profile == null ||
        state.busy ||
        profile.photos.length >= UserProfile.maxPhotos) {
      return;
    }
    _emit(state.copyWith(busy: true, photoFailed: false));
    try {
      final photo = await _photos.add(source);
      if (photo != null) {
        final latest = _profiles.current ?? profile;
        await _profiles.save(
          latest.copyWith(photos: [...latest.photos, photo]),
        );
      }
      _emit(state.copyWith(busy: false));
    } on Exception {
      _emit(state.copyWith(busy: false, photoFailed: true));
    }
  }

  /// Moves [photo] first: the main photo.
  Future<void> makeMain(ProfilePhoto photo) => _savePhotos(
    (photos) => [photo, ...photos.where((p) => p.id != photo.id)],
  );

  Future<void> removePhoto(ProfilePhoto photo) async {
    await _savePhotos((photos) => [...photos.where((p) => p.id != photo.id)]);
    await _photos.delete(photo);
  }

  /// Women: share the main photo with a match after accepting.
  Future<void> setSharePhoto(bool share) async {
    final profile = _profiles.current;
    if (profile == null) return;
    await _profiles.save(profile.copyWith(sharePhotoWithMatch: share));
  }

  // --- leaving -------------------------------------------------------------------

  /// Call before leaving: if answers changed, Khalty rewrites the brief (in
  /// the language it was written in). A failure keeps the old brief.
  Future<void> finish() async {
    final profile = _profiles.current;
    final analysis = profile?.analysis;
    if (profile == null || analysis == null || !state.answersChanged) return;
    _emit(state.copyWith(refreshingBrief: true));
    try {
      final brief = await _ai.refreshBrief(
        IntakeAnalysisRequest(
          gender: profile.gender,
          language: analysis.language,
          name: profile.name ?? '',
          answers: _engine.toAiPayload(profile.answers),
          introduction: profile.selfIntro?.text,
        ),
      );
      final latest = _profiles.current ?? profile;
      await _profiles.save(
        latest.copyWith(analysis: analysis.copyWith(brief: brief)),
      );
    } on KhaltyAiException {
      // Keep the old brief.
    }
    _emit(state.copyWith(refreshingBrief: false, answersChanged: false));
  }

  // --- internals -----------------------------------------------------------------

  Future<void> _savePhotos(
    List<ProfilePhoto> Function(List<ProfilePhoto>) change,
  ) async {
    final profile = _profiles.current;
    if (profile == null) return;
    await _profiles.save(profile.copyWith(photos: change(profile.photos)));
  }

  void _show(UserProfile? profile) {
    if (profile == null) {
      _emit(state.copyWith(sections: const []));
      return;
    }
    final answers = profile.answers;
    final sections = <EditSection>[
      for (final chapter in _engine.config.chapters)
        EditSection(
          chapter: chapter,
          rows: [
            for (final field in _engine.fields)
              if (field.chapter == chapter.id &&
                  _engine.applies(field, answers))
                _row(field, answers),
          ],
        ),
    ].where((s) => s.rows.isNotEmpty).toList();
    _emit(state.copyWith(profile: profile, sections: sections));
  }

  EditRow _row(FieldDef field, Answers answers) {
    final effective = _engine.effective(field.key, answers);
    return EditRow(
      field: field,
      value: effective?.value,
      source: _engine.config.field(effective?.sourceKey ?? field.key)!,
    );
  }

  void _emit(EditProfileState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
