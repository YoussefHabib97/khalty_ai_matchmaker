import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
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
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/country_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/invalid_answer_text.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/multi_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/range_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/typed_answer_input.dart';
import 'package:material_ui/material_ui.dart';

/// One question: Khalty's bubble, "Why this question?", the answer input and
/// the Skip / Continue buttons. Give it a key per question so drafts (typed
/// text, picked chips, slider) start fresh on each one; coming back to an
/// answered question starts from the earlier answer.
class QuestionStepBody extends StatefulWidget {
  const QuestionStepBody({super.key, required this.field, required this.state});

  final FieldDef field;
  final IntakeState state;

  @override
  State<QuestionStepBody> createState() => _QuestionStepBodyState();
}

class _QuestionStepBodyState extends State<QuestionStepBody> {
  late final TextEditingController _text;
  late List<String> _ids;
  late List<String> _custom;
  RangeAnswer? _range;

  FieldDef get _field => widget.field;
  InputType get _input => _field.input;
  bool get _isTyped => _input == InputType.text || _input == InputType.number;

  /// Inputs answered with Continue (choices and countries answer on tap).
  bool get _hasContinue =>
      _isTyped || _input == InputType.multi || _input == InputType.range;

  @override
  void initState() {
    super.initState();
    final earlier = widget.state.answers[_field.key];
    _text = TextEditingController(
      text: switch (earlier) {
        TextAnswer(:final text) => text,
        NumberAnswer(:final value) => '$value',
        _ => '',
      },
    );
    final multi = earlier is MultiAnswer ? earlier : null;
    _ids = [...?multi?.optionIds];
    _custom = [...?multi?.custom];
    _range = widget.state.suggestedRange;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<IntakeCubit>();
    switch (_input) {
      case InputType.number:
        cubit.submitNumber(_text.text);
      case InputType.text:
        cubit.submitText(_text.text);
      case InputType.multi:
        cubit.submit(MultiAnswer(_ids, custom: _custom));
      case InputType.range:
        if (_range case final range?) cubit.submit(range);
      case InputType.choice || InputType.country || InputType.countryOptional:
        break; // answered on tap
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<IntakeCubit>();
    final l10n = context.l10n;
    final language = context.appLanguage;
    final colors = Theme.of(context).colorScheme;
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
              _field,
              reason,
            ),
            null => null,
          };
    final enabled = !state.isSaving;
    // A confirm-style country question with nothing to confirm asks
    // "Which country…?" straight away.
    final question =
        _input == InputType.country &&
            suggested == null &&
            _field.questionPick != null
        ? _field.questionPick!
        : _field.question;
    final pickTitle = (_field.questionPick ?? _field.question).resolve(
      language,
      state.gender,
      vars: vars,
    );

    final Widget input = switch (_input) {
      InputType.text || InputType.number => TypedAnswerInput(
        controller: _text,
        numeric: _input == InputType.number,
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
      InputType.multi => MultiAnswerInput(
        options: _field.optionsFor(state.gender),
        language: language,
        gender: state.gender,
        selectedIds: _ids,
        custom: _custom,
        maxPick: _field.maxPick,
        allowText: _field.allowText,
        enabled: enabled,
        onChanged: (ids, custom) {
          setState(() {
            _ids = ids;
            _custom = custom;
          });
          cubit.draftChanged();
        },
      ),
      InputType.range => RangeAnswerInput(
        value: _range!,
        min: _field.min!,
        max: _field.max!,
        enabled: enabled,
        onChanged: (range) => setState(() => _range = range),
      ),
      InputType.country || InputType.countryOptional => CountryAnswerInput(
        suggested: suggested,
        optional: _input == InputType.countryOptional,
        noneSelected: state.answers[_field.key] is NoneAnswer,
        pickTitle: pickTitle,
        enabled: enabled,
        onCountry: (iso) => cubit.submit(CountryAnswer(iso)),
        onNone: () => cubit.submit(const NoneAnswer()),
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
                    text: question.resolve(language, state.gender, vars: vars),
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
        if (_hasContinue || _field.optional)
          DefaultPadding(
            child: Row(
              children: [
                if (_field.optional)
                  TextButton(
                    key: const Key('intakeSkip'),
                    onPressed: enabled ? cubit.skip : null,
                    child: Text(l10n.intakeSkip),
                  ),
                const Spacer(),
                if (_hasContinue)
                  FilledButton(
                    key: const Key('intakeContinue'),
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
