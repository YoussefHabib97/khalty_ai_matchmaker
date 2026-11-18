import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/choice_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/country_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/multi_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/range_answer_input.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/typed_answer_input.dart';
import 'package:material_ui/material_ui.dart';

/// Places the answer [input] and the [actions] row (Skip / submit; null when
/// the input answers on tap and the question isn't optional).
typedef AnswerEditorLayout = Widget Function(
  BuildContext context,
  Widget input,
  Widget? actions,
);

/// Answering one question, shared by the questionnaire and profile editing:
/// the right input for the question, its draft (typed text, picked chips,
/// slider), Skip for optional questions and the submit button. Choices and
/// countries answer on tap; the others with the submit button. Give it a
/// key per question so drafts start fresh.
class AnswerEditor extends StatefulWidget {
  const AnswerEditor({
    super.key,
    required this.field,
    required this.gender,
    required this.submitLabel,
    required this.onSubmit,
    required this.onSubmitTyped,
    required this.layout,
    this.earlier,
    this.suggestedCountry,
    this.suggestedRange,
    this.pickTitle,
    this.errorText,
    this.enabled = true,
    this.onSkip,
    this.onDraftChanged,
  });

  final FieldDef field;

  /// The user's gender (options and labels).
  final Gender gender;

  /// The current answer, to start from.
  final AnswerValue? earlier;

  /// Country questions: the country to confirm.
  final Country? suggestedCountry;

  /// Range questions: where the slider starts when there's no answer yet.
  final RangeAnswer? suggestedRange;

  /// Country questions: title of the country list.
  final String? pickTitle;
  final String? errorText;
  final bool enabled;
  final String submitLabel;

  /// An answer from a choice, chips, slider or country.
  final ValueChanged<AnswerValue> onSubmit;

  /// What was typed into a text or number question (parsed by the caller,
  /// e.g. with `QuestionnaireEngine.parseTyped`).
  final ValueChanged<String> onSubmitTyped;

  /// Skip, shown on optional questions when given.
  final VoidCallback? onSkip;

  /// The draft changed (e.g. to hide an error).
  final VoidCallback? onDraftChanged;
  final AnswerEditorLayout layout;

  @override
  State<AnswerEditor> createState() => _AnswerEditorState();
}

class _AnswerEditorState extends State<AnswerEditor> {
  late final TextEditingController _text;
  late List<String> _ids;
  late List<String> _custom;
  RangeAnswer? _range;

  FieldDef get _field => widget.field;
  InputType get _input => _field.input;
  bool get _isTyped => _input == InputType.text || _input == InputType.number;
  bool get _hasSubmit =>
      _isTyped || _input == InputType.multi || _input == InputType.range;

  @override
  void initState() {
    super.initState();
    final earlier = widget.earlier;
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
    if (_input == InputType.range) {
      _range = switch (earlier) {
        final RangeAnswer range => range,
        _ => widget.suggestedRange ?? RangeAnswer(_field.min!, _field.max!),
      };
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    switch (_input) {
      case InputType.text || InputType.number:
        widget.onSubmitTyped(_text.text);
      case InputType.multi:
        widget.onSubmit(MultiAnswer(_ids, custom: _custom));
      case InputType.range:
        if (_range case final range?) widget.onSubmit(range);
      case InputType.choice || InputType.country || InputType.countryOptional:
        break; // answered on tap
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.enabled;
    final error = widget.errorText;

    final Widget field = switch (_input) {
      InputType.text || InputType.number => TypedAnswerInput(
        controller: _text,
        numeric: _input == InputType.number,
        enabled: enabled,
        errorText: error,
        onChanged: (_) => widget.onDraftChanged?.call(),
        onSubmitted: _submit,
      ),
      InputType.choice => ChoiceAnswerInput(
        options: _field.optionsFor(widget.gender),
        language: language,
        gender: widget.gender,
        enabled: enabled,
        selectedId: switch (widget.earlier) {
          ChoiceAnswer(:final optionId) => optionId,
          _ => null,
        },
        onSelected: (id) => widget.onSubmit(ChoiceAnswer(id)),
      ),
      InputType.multi => MultiAnswerInput(
        options: _field.optionsFor(widget.gender),
        language: language,
        gender: widget.gender,
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
          widget.onDraftChanged?.call();
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
        suggested: widget.suggestedCountry,
        optional: _input == InputType.countryOptional,
        noneSelected: widget.earlier is NoneAnswer,
        pickTitle: widget.pickTitle ?? l10n.chooseCountry,
        enabled: enabled,
        onCountry: (iso) => widget.onSubmit(CountryAnswer(iso)),
        onNone: () => widget.onSubmit(const NoneAnswer()),
      ),
    };

    final input = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
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
    );

    final showSkip = _field.optional && widget.onSkip != null;
    final actions = _hasSubmit || showSkip
        ? Row(
            children: [
              if (showSkip)
                TextButton(
                  key: const Key('answerSkip'),
                  onPressed: enabled ? widget.onSkip : null,
                  child: Text(l10n.intakeSkip),
                ),
              const Spacer(),
              if (_hasSubmit)
                FilledButton(
                  key: const Key('answerSubmit'),
                  onPressed: enabled ? _submit : null,
                  child: Text(widget.submitLabel),
                ),
            ],
          )
        : null;

    return widget.layout(context, input, actions);
  }
}
