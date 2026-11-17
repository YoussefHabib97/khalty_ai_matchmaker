import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/khalty_bubble.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/why_question_sheet.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/choice_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/invalid_answer_text.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/pending_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/typed_answer_input.dart';
import 'package:material_ui/material_ui.dart';

/// One question: Khalty's bubble, "Why this question?", the answer input and
/// the Skip / Continue buttons. Give it a key per question so a typed draft
/// starts fresh on each one.
class QuestionStepBody extends StatefulWidget {
  const QuestionStepBody({super.key, required this.field, required this.state});

  final FieldDef field;
  final IntakeState state;

  @override
  State<QuestionStepBody> createState() => _QuestionStepBodyState();
}

class _QuestionStepBodyState extends State<QuestionStepBody> {
  late final TextEditingController _draft;

  FieldDef get _field => widget.field;
  bool get _isTyped =>
      _field.input == InputType.text || _field.input == InputType.number;

  @override
  void initState() {
    super.initState();
    // Coming back to an answered question shows the earlier answer.
    _draft = TextEditingController(
      text: switch (widget.state.answers[_field.key]) {
        TextAnswer(:final text) => text,
        NumberAnswer(:final value) => '$value',
        _ => '',
      },
    );
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<IntakeCubit>();
    if (_field.input == InputType.number) {
      cubit.submitNumber(_draft.text);
    } else {
      cubit.submitText(_draft.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<IntakeCubit>();
    final l10n = context.l10n;
    final language = context.appLanguage;
    final colors = Theme.of(context).colorScheme;
    final vars = {'name': ?state.name};
    final script = state.config.script;

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
              _field,
              reason,
            ),
            null => null,
          };
    final enabled = !state.isSaving;

    final Widget input = switch (_field.input) {
      InputType.text || InputType.number => TypedAnswerInput(
        controller: _draft,
        numeric: _field.input == InputType.number,
        enabled: enabled,
        errorText: error,
        onChanged: (_) => cubit.draftChanged(),
        onSubmitted: _submit,
      ),
      InputType.choice => ChoiceAnswerInput(
        options: _field.optionsFor(state.gender),
        language: language,
        gender: state.gender,
        enabled: enabled,
        selectedId: switch (state.answers[_field.key]) {
          ChoiceAnswer(:final optionId) => optionId,
          _ => null,
        },
        onSelected: cubit.choose,
      ),
      // TEMPORARY until step 9.
      _ => PendingAnswerInput(
        onUseSample: enabled ? cubit.useSampleAnswer : null,
      ),
    };

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DefaultPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KhaltyBubble(
                    reply: reply,
                    text: _field.question.resolve(
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
                        _field.why.resolve(language, state.gender, vars: vars),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  input,
                  // Typed inputs show the error inside the field.
                  if (error != null && !_isTyped)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error,
                        style: context.bodyMedium.copyWith(color: colors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_isTyped || _field.optional)
          DefaultPadding(
            child: Row(
              children: [
                if (_field.optional)
                  TextButton(
                    onPressed: enabled ? cubit.skip : null,
                    child: Text(l10n.intakeSkip),
                  ),
                const Spacer(),
                if (_isTyped)
                  FilledButton(
                    onPressed: enabled ? _submit : null,
                    child: Text(l10n.intakeContinue),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
