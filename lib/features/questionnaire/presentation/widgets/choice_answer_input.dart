import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/option_card.dart';
import 'package:material_ui/material_ui.dart';

/// One answer out of a list: a card per option, the current answer
/// highlighted. Tapping an option answers.
class ChoiceAnswerInput extends StatelessWidget {
  const ChoiceAnswerInput({
    super.key,
    required this.options,
    required this.language,
    required this.gender,
    required this.onSelected,
    this.selectedId,
    this.enabled = true,
  });

  /// The options this user may pick (already gender-filtered).
  final List<OptionDef> options;
  final AppLanguage language;

  /// The user's gender, for gendered labels.
  final Gender gender;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final option in options)
          OptionCard(
            key: Key('option-${option.id}'),
            label: option.label.resolve(language, gender),
            selected: option.id == selectedId,
            onTap: enabled ? () => onSelected(option.id) : null,
          ),
      ],
    );
  }
}
