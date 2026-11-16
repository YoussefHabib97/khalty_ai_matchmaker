import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// Khalty tab: her always-open chat and status updates. Placeholder.
class KhaltyTabView extends StatelessWidget {
  const KhaltyTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.tabKhalty;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
