import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// A titled card on the review screen. [attention] highlights it (the
/// "Please check" card).
class ReviewSectionCard extends StatelessWidget {
  const ReviewSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.attention = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = attention ? colors.onTertiaryContainer : null;
    return Card.filled(
      color: attention ? colors.tertiaryContainer : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                if (icon != null) Icon(icon, size: 20, color: foreground),
                Expanded(
                  child: Text(
                    title,
                    style: context.labelLarge.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            DefaultTextStyle.merge(
              style: context.bodyLarge.copyWith(color: foreground, height: 1.5),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
