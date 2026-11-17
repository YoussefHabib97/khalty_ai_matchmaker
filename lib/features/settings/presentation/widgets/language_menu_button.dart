import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:material_ui/material_ui.dart';

/// Compact language switch for app bars: a globe icon that opens a menu of
/// the languages, the current one ticked. Language names are always written
/// in their own language. See [LanguageSelector] for the full dropdown.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LocaleCubit>();
    final l10n = context.l10n;
    final current = cubit.state.languageCode;
    return MenuAnchor(
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.language),
        tooltip: l10n.changeLanguage,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        for (final (code, label) in [
          ('en', l10n.languageEnglish),
          ('ar', l10n.languageArabic),
        ])
          MenuItemButton(
            // An empty icon keeps both names aligned.
            leadingIcon: Icon(code == current ? Icons.check : null),
            onPressed: () => cubit.setLocale(Locale(code)),
            child: Text(label),
          ),
      ],
    );
  }
}
