import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Temporary body for screens that aren't built yet.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: DefaultPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            title,
            style: context.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            context.l10n.placeholderComingSoon,
            style: context.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
