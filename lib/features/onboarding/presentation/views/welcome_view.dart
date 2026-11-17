import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/khalty_avatar.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_selector.dart';
import 'package:material_ui/material_ui.dart';

/// First screen for signed-out users: who Khalty is, the language, and
/// "Get started".
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.onGetStarted});

  /// Called when "Get started" is tapped (open sign-up).
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: DefaultPadding(
              child: Column(
                spacing: 16,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LanguageSelector(),
                  ),
                  const KhaltyAvatar(radius: 56),
                  Text(l10n.welcomeMeet, style: context.headlineMedium),
                  Text(l10n.welcomeTagline, style: context.titleLarge),
                  Text(
                    l10n.welcomeTitle,
                    style: context.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.welcomeBody,
                    style: context.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onGetStarted,
                      child: Text(l10n.getStarted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
