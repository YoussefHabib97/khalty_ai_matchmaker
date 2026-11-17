import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
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
          _OptionCard(
            key: Key('option-${option.id}'),
            label: option.label.resolve(language, gender),
            selected: option.id == selectedId,
            onTap: enabled ? () => onSelected(option.id) : null,
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.bodyLarge.copyWith(
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
