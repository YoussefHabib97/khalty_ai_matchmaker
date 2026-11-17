import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// TEMPORARY (removed in step 9): stands in for the country, multi-select
/// and range inputs, so the whole questionnaire can be walked through.
class PendingAnswerInput extends StatelessWidget {
  const PendingAnswerInput({super.key, required this.onUseSample});

  final VoidCallback? onUseSample;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            Text(
              l10n.intakeComingSoon,
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            OutlinedButton(
              onPressed: onUseSample,
              child: Text(l10n.intakeUseSample),
            ),
          ],
        ),
      ),
    );
  }
}
