import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_state.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_request.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/entities/intake_analysis_result.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/repos/khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// ViewModel for the self-introduction: send (or skip), Khalty's analysis,
/// at most one request for more, then the introduction, the analysis and
/// `selfIntroDoneAt` are saved **together**, so there is never a
/// half-finished state. The session then moves on to the review.
class SelfIntroCubit extends Cubit<SelfIntroState> {
  SelfIntroCubit({
    required ProfileRepository profiles,
    required KhaltyAiRepository ai,
    required QuestionnaireEngine Function(Gender gender) engineFor,
    DateTime Function()? now,
  }) : this._(
         profiles,
         ai,
         // Without a profile any engine will do: the router is leaving.
         engineFor(profiles.current?.gender ?? Gender.female),
         now ?? DateTime.now,
       );

  SelfIntroCubit._(this._profiles, this._ai, this._engine, this._now)
    : super(
        SelfIntroState(
          phase: _profiles.current == null
              ? SelfIntroPhase.done
              : SelfIntroPhase.writing,
          gender: _engine.gender,
          script: _engine.config.script,
          name: _profiles.current?.name,
          // Rewriting from the review starts from the earlier text.
          draft: _profiles.current?.selfIntro?.text ?? '',
        ),
      );

  final ProfileRepository _profiles;
  final KhaltyAiRepository _ai;
  final QuestionnaireEngine _engine;
  final DateTime Function() _now;

  /// Khalty already asked once for more: the next try is accepted.
  bool _askedOnce = false;

  /// What was last sent (null = skipped), for "Try again".
  String? _lastIntro;

  /// Sends the introduction, written in [language].
  Future<void> send(String text, AppLanguage language) async {
    final intro = text.trim();
    if (intro.isEmpty || !state.canWrite) return;
    await _analyse(intro, language);
  }

  /// "Not now": analyse the answers only.
  Future<void> skip(AppLanguage language) async {
    if (!state.canWrite) return;
    await _analyse(null, language);
  }

  /// After a failure: the same request again.
  Future<void> retry(AppLanguage language) async {
    if (state.phase != SelfIntroPhase.failed) return;
    await _analyse(_lastIntro, language);
  }

  Future<void> _analyse(String? intro, AppLanguage language) async {
    final profile = _profiles.current;
    if (profile == null) return;
    _lastIntro = intro;
    _emit(
      state.copyWith(
        phase: SelfIntroPhase.analysing,
        sent: intro,
        draft: intro ?? state.draft,
        khaltyReply: null,
      ),
    );

    final IntakeAnalysisResult result;
    try {
      result = await _ai.analyseIntake(
        IntakeAnalysisRequest(
          gender: profile.gender,
          language: language,
          name: profile.name ?? '',
          answers: _engine.toAiPayload(profile.answers),
          introduction: intro,
          mustAccept: _askedOnce,
        ),
      );
    } on KhaltyAiException {
      _emit(state.copyWith(phase: SelfIntroPhase.failed));
      return;
    }

    switch (result) {
      case IntroNeedsMore(:final reply):
        _askedOnce = true;
        _emit(
          state.copyWith(phase: SelfIntroPhase.needsMore, khaltyReply: reply),
        );
      case IntakeAnalysed(:final analysis):
        final now = _now();
        try {
          final latest = _profiles.current ?? profile;
          await _profiles.save(
            latest.copyWith(
              selfIntro: intro == null
                  ? SelfIntro.skipped(at: now)
                  : SelfIntro.typed(intro, at: now),
              analysis: analysis,
              progress: latest.progress.copyWith(selfIntroDoneAt: now),
            ),
          );
        } on Exception {
          _emit(state.copyWith(phase: SelfIntroPhase.failed));
          return;
        }
        _emit(state.copyWith(phase: SelfIntroPhase.done));
    }
  }

  void _emit(SelfIntroState next) {
    if (!isClosed) emit(next);
  }
}
