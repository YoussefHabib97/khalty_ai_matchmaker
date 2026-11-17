import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/intake_intro_card.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/intake_progress_header.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/question_step_body.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_menu_button.dart';
import 'package:material_ui/material_ui.dart';

/// The questionnaire, one question per screen, with Khalty's greeting and
/// chapter intros in between. Expects an [IntakeCubit] above it. When the
/// last answer is saved the session changes and the router moves on, so
/// this screen needs no navigation callback.
class IntakeView extends StatelessWidget {
  const IntakeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntakeCubit, IntakeState>(
      builder: (context, state) {
        final cubit = context.read<IntakeCubit>();
        final language = context.appLanguage;
        final config = state.config;
        final chapterId = switch (state.step) {
          GreetingStep(:final next) => next.chapter,
          ChapterIntroStep(:final chapter) => chapter.id,
          QuestionStep(:final field) => field.chapter,
          DoneStep() => config.chapters.last.id,
        };
        final title = state.step is GreetingStep
            ? context.l10n.intakeTitle
            : config.chapter(chapterId).title.resolve(language, state.gender);

        return PopScope(
          // System Back steps back through the questions; on the greeting
          // it leaves the app as usual.
          canPop: !state.canGoBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: state.canGoBack
                  ? BackButton(onPressed: cubit.back)
                  : null,
              title: Text(title),
              actions: const [LanguageMenuButton()],
              bottom: state.step is DoneStep
                  ? null
                  : IntakeProgressHeader(
                      chapter: chapterId,
                      chapterCount: config.chapters.length,
                      remaining: state.progress.remaining,
                      fraction: state.progress.fraction,
                    ),
            ),
            body: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(state.step),
                  child: _body(context, state, cubit),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, IntakeState state, IntakeCubit cubit) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    return switch (state.step) {
      GreetingStep() => IntakeIntroCard(
        text: state.config.script.greeting.resolve(language, state.gender),
        buttonLabel: l10n.intakeBegin,
        onPressed: cubit.continueToQuestion,
      ),
      ChapterIntroStep(:final chapter) => IntakeIntroCard(
        title: chapter.title.resolve(language, state.gender),
        text: chapter.intro!.resolve(
          language,
          state.gender,
          vars: {'name': ?state.name},
        ),
        buttonLabel: l10n.intakeContinue,
        onPressed: cubit.continueToQuestion,
      ),
      QuestionStep(:final field) => QuestionStepBody(
        key: ValueKey(field.key),
        field: field,
        state: state,
      ),
      // Saved; the router is moving on to the self-introduction.
      DoneStep() => const Center(child: CircularProgressIndicator()),
    };
  }
}
