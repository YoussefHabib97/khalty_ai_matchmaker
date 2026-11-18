import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_completeness.dart';
import 'package:material_ui/material_ui.dart';

/// "Khalty knows you 72%" with a bar and a nudge towards the biggest
/// missing piece.
class KnowsYouCard extends StatelessWidget {
  const KnowsYouCard({super.key, required this.completeness});

  final Completeness completeness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = switch (completeness.nextStep) {
      ProfilePart.questions => l10n.hintQuestions,
      ProfilePart.introduction => l10n.hintIntroduction,
      ProfilePart.aboutMe => l10n.hintAboutMe,
      ProfilePart.photo => l10n.hintPhoto,
      ProfilePart.optionalDetails => l10n.hintOptional,
      null => l10n.hintComplete,
    };
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              l10n.knowsYou(completeness.percent),
              style: context.titleLarge,
            ),
            LinearProgressIndicator(
              value: completeness.percent / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            Text(hint, style: context.bodyMedium),
          ],
        ),
      ),
    );
  }
}
