import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// The self-introduction, chat style. Placeholder until step 10.
class SelfIntroView extends StatelessWidget {
  const SelfIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.selfIntroTitle;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
