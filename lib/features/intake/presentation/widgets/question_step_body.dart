import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/khalty_bubble.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/why_question_sheet.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/answer_editor.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/invalid_answer_text.dart';
import 'package:material_ui/material_ui.dart';

/// One question: Khalty's bubble, "Why this question?", the answer input and
/// the Skip / Continue buttons (an [AnswerEditor]). Give it a key per
/// question so drafts start fresh.
class QuestionStepBody extends StatelessWidget {
  const QuestionStepBody({super.key, required this.field, required this.state});

  final FieldDef field;
  final IntakeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IntakeCubit>();
    final l10n = context.l10n;
    final language = context.appLanguage;
    final script = state.config.script;
    final suggested = switch (state.suggestedCountry) {
      final iso? => countryByIso(iso),
      null => null,
    };
    final vars = {
      'name': ?state.name,
      // The country being confirmed: "Are you living in {detected}?",
      // "Is your nationality {residence}?".
      if (suggested != null) ...{
        'detected': suggested.name(language),
        'residence': suggested.name(language),
      },
    };

    final reply = switch (state.reply) {
      NameReply() => script.nameAck.resolve(language, state.gender, vars: vars),
      GeneralReply(:final index) => script.acks.resolve(
        language,
        index,
        vars: vars,
      ),
      null => null,
    };
    final error = state.saveFailed
        ? l10n.answerSaveFailed
        : switch (state.invalid) {
            final reason? => invalidAnswerText(
              l10n,
              language,
              state.gender,
              field,
              reason,
            ),
            null => null,
          };
    // A confirm-style country question with nothing to confirm asks
    // "Which country…?" straight away.
    final question =
        field.input == InputType.country &&
            suggested == null &&
            field.questionPick != null
        ? field.questionPick!
        : field.question;

    return AnswerEditor(
      field: field,
      gender: state.gender,
      earlier: state.answers[field.key],
      suggestedCountry: suggested,
      suggestedRange: state.suggestedRange,
      pickTitle: (field.questionPick ?? field.question).resolve(
        language,
        state.gender,
        vars: vars,
      ),
      errorText: error,
      enabled: !state.isSaving,
      submitLabel: l10n.intakeContinue,
      onSubmit: cubit.submit,
      onSubmitTyped: cubit.submitTyped,
      onSkip: cubit.skip,
      onDraftChanged: cubit.draftChanged,
      layout: (context, input, actions) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DefaultPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KhaltyBubble(
                      reply: reply,
                      text: question.resolve(
                        language,
                        state.gender,
                        vars: vars,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: Text(l10n.intakeWhyThisQuestion),
                        onPressed: () => showWhyQuestionSheet(
                          context,
                          field.why.resolve(language, state.gender, vars: vars),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    input,
                  ],
                ),
              ),
            ),
          ),
          if (actions != null) DefaultPadding(child: actions),
        ],
      ),
    );
  }
}
