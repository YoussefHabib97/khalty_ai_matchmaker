import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// Khalty's "here's what I understood" summary. Placeholder until step 10.
class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.reviewTitle;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
