import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/placeholder_body.dart';
import 'package:material_ui/material_ui.dart';

/// The questionnaire, one question per screen. Placeholder until steps 8-9.
class IntakeView extends StatelessWidget {
  const IntakeView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.intakeTitle;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PlaceholderBody(title: title),
    );
  }
}
