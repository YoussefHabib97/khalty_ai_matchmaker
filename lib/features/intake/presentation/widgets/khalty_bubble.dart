import 'package:khalty_ai_matchmaker/core/shared/widgets/khalty_avatar.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Khalty speaking: her avatar and a speech bubble with an optional short
/// [reply] to the previous answer above the main [text].
class KhaltyBubble extends StatelessWidget {
  const KhaltyBubble({super.key, required this.text, this.reply});

  final String text;
  final String? reply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const KhaltyAvatar(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(4),
                topEnd: Radius.circular(16),
                bottomStart: Radius.circular(16),
                bottomEnd: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                if (reply != null)
                  Text(
                    reply!,
                    style: context.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                Text(
                  text,
                  style: context.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
