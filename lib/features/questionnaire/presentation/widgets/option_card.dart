import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// One selectable answer: a bordered card, highlighted with a tick when
/// [selected]. Disabled when [onTap] is null.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;

  /// E.g. a flag before the label.
  final Widget? leading;
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
                ?leading,
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
