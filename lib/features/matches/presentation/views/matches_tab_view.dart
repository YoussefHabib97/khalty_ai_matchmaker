import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// Matches tab: suggestions and waiting. Placeholder.
class MatchesTabView extends StatelessWidget {
  const MatchesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.tabMatches;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
