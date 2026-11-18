import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// The user's own chat message, on the end side.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(16),
              topEnd: Radius.circular(4),
              bottomStart: Radius.circular(16),
              bottomEnd: Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: context.bodyLarge.copyWith(color: colors.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
