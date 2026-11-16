import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// "I am… a man / a woman".
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final Gender? selected;
  final ValueChanged<Gender> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(l10n.genderQuestion, style: context.titleLarge),
        Wrap(
          spacing: 12,
          children: [
            for (final (gender, label) in [
              (Gender.male, l10n.genderMan),
              (Gender.female, l10n.genderWoman),
            ])
              ChoiceChip(
                label: Text(label),
                selected: selected == gender,
                onSelected: (_) => onSelected(gender),
              ),
          ],
        ),
        if (errorText != null)
          Text(
            errorText!,
            style: context.bodySmall.copyWith(color: colors.error),
          ),
      ],
    );
  }
}
