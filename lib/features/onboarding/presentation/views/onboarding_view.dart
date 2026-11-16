import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/language_selector.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/theme_switcher_widget.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Temporary placeholder; replaced by the welcome flow in a later step.
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: DefaultPadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              Text(
                l10n.welcomeGreeting('other'),
                style: context.headlineMedium,
              ),
              const LanguageSelector(),
              Text(l10n.themeLabel, style: context.titleLarge),
              const ThemeSwitcherWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
