import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/digits.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_autofill.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// ViewModel for the questionnaire: one question at a time, with Khalty's
/// greeting and chapter intros in between. The questionnaire rules (which
/// question comes next, validation, progress) come from the
/// [QuestionnaireEngine]; this cubit only orders the cards and saves every
/// answer straight away, so the app resumes at the same question.
///
/// When the last answer is saved, the session moves on to the
/// self-introduction and the router leaves this screen.
class IntakeCubit extends Cubit<IntakeState> {
  IntakeCubit({
    required ProfileRepository profiles,
    required QuestionnaireEngine Function(Gender gender) engineFor,
    DateTime Function()? now,
  }) : this._(
         profiles,
         // Without a profile (signed out meanwhile) any engine will do: the
         // screen shows DoneStep and the router is about to leave it.
         engineFor(profiles.current?.gender ?? Gender.female),
         now ?? DateTime.now,
       );

  IntakeCubit._(this._profiles, this._engine, this._now)
    : super(_initialState(_engine, _profiles.current?.answers));

  final ProfileRepository _profiles;

  /// The rules for this user's gender.
  final QuestionnaireEngine _engine;
  final DateTime Function() _now;

  /// How many general replies were shown, so they cycle in order.
  int _replies = 0;

  static IntakeState _initialState(QuestionnaireEngine engine, Answers? saved) {
    final answers = saved ?? Answers();
    final next = saved == null ? null : engine.nextField(answers);
    final IntakeStep step;
    if (next == null) {
      step = const DoneStep();
    } else if (answers.isEmpty) {
      step = GreetingStep(next);
    } else {
      step = _arrive(engine, next, answers);
    }
    return IntakeState(
      step: step,
      answers: answers,
      progress: engine.progress(answers),
      gender: engine.gender,
      config: engine.config,
    );
  }

  // --- events from the view ---------------------------------------------------

  /// "Let's begin" on the greeting, or "Continue" on a chapter intro.
  void continueToQuestion() {
    final next = switch (state.step) {
      GreetingStep(:final next) || ChapterIntroStep(:final next) => next,
      _ => null,
    };
    if (next != null) _go(QuestionStep(next));
  }

  /// A typed answer to a text question.
  Future<void> submitText(String text) => _answer(TextAnswer(text));

  /// A typed answer to a number question, in any digits (29, ٢٩, ۲۹).
  Future<void> submitNumber(String text) async {
    final number = parseLocalizedInt(text);
    if (number == null) {
      _emit(
        state.copyWith(
          invalid: text.trim().isEmpty
              ? InvalidReason.empty
              : InvalidReason.wrongType,
          saveFailed: false,
        ),
      );
      return;
    }
    await _answer(NumberAnswer(number));
  }

  /// A tapped option of a choice question.
  Future<void> choose(String optionId) => _answer(ChoiceAnswer(optionId));

  /// Skip, on optional questions only.
  Future<void> skip() => _answer(const SkippedAnswer());

  /// TEMPORARY (until step 9 builds these inputs): answers a country,
  /// multi-select or range question with a simple valid answer.
  Future<void> useSampleAnswer() async {
    if (state.step case QuestionStep(:final field)) {
      await _answer(
        QuestionnaireAutofill.defaultAnswer(_engine, field, state.answers),
      );
    }
  }

  /// The user edited their typed answer: hide the error.
  void draftChanged() {
    if (state.invalid != null || state.saveFailed) {
      _emit(state.copyWith(invalid: null, saveFailed: false));
    }
  }

  /// Back: to the previous question that applies (skipping intros), or to
  /// the greeting from the first question.
  void back() {
    final current = switch (state.step) {
      QuestionStep(:final field) => field,
      ChapterIntroStep(:final next) => next,
      _ => null,
    };
    if (current == null) return;
    final previous = _engine.previousField(current.key, state.answers);
    _go(previous == null ? GreetingStep(current) : QuestionStep(previous));
  }

  // --- internals --------------------------------------------------------------

  Future<void> _answer(AnswerValue value) async {
    final field = switch (state.step) {
      QuestionStep(:final field) => field,
      _ => null,
    };
    if (field == null || state.isSaving) return;

    final engine = _engine;
    final Answers answers;
    try {
      answers = engine.apply(state.answers, field.key, value);
    } on InvalidAnswerException catch (e) {
      _emit(state.copyWith(invalid: e.reason, saveFailed: false));
      return;
    }

    final done = engine.nextField(answers) == null;
    _emit(state.copyWith(isSaving: true, invalid: null, saveFailed: false));
    if (!await _save(answers, done: done)) {
      _emit(state.copyWith(isSaving: false, saveFailed: true));
      return;
    }
    if (done) {
      _go(const DoneStep(), answers: answers);
      return;
    }

    // Move forward one question (also through ones already answered after
    // going Back); fall back to the first unanswered one.
    final next =
        engine.fieldAfter(field.key, answers) ?? engine.nextField(answers)!;
    final step = _arrive(engine, next, answers);
    final IntakeReply? reply = step is! QuestionStep
        ? null
        : field.key == FieldKeys.name
        ? const NameReply()
        : GeneralReply(_replies++);
    _go(step, answers: answers, reply: reply);
  }

  /// The step for arriving at [next]: its chapter's intro first, when it
  /// starts a new chapter that has one.
  static IntakeStep _arrive(
    QuestionnaireEngine engine,
    FieldDef next,
    Answers answers,
  ) {
    final previous = engine.previousField(next.key, answers);
    final startsChapter = previous == null || previous.chapter != next.chapter;
    final chapter = engine.config.chapter(next.chapter);
    if (startsChapter && chapter.intro != null) {
      return ChapterIntroStep(chapter, next);
    }
    return QuestionStep(next);
  }

  Future<bool> _save(Answers answers, {required bool done}) async {
    final profile = _profiles.current;
    if (profile == null) return false;
    try {
      await _profiles.save(
        profile.copyWith(
          answers: answers,
          progress: done
              ? profile.progress.copyWith(intakeDoneAt: _now())
              : null,
        ),
      );
      return true;
    } on Exception {
      return false;
    }
  }

  void _go(IntakeStep step, {Answers? answers, IntakeReply? reply}) {
    final all = answers ?? state.answers;
    _emit(
      IntakeState(
        step: step,
        answers: all,
        progress: _engine.progress(all),
        gender: state.gender,
        config: state.config,
        reply: reply,
      ),
    );
  }

  void _emit(IntakeState next) {
    if (!isClosed) emit(next);
  }
}
