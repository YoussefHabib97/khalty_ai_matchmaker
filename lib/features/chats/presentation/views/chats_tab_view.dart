import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// Chats tab: introduction chats. Placeholder.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.tabChats;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
