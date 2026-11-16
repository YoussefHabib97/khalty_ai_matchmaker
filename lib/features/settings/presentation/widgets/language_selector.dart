import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Dropdown for the app language (one at a time). Language names are always
/// written in their own language, so they read the same in either locale.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LocaleCubit>();
    final l10n = context.l10n;
    return DropdownMenu<String>(
      initialSelection: cubit.state.languageCode,
      label: Text(l10n.languageLabel),
      leadingIcon: const Icon(Icons.language),
      requestFocusOnTap: false,
      enableSearch: false,
      onSelected: (code) {
        if (code != null) cubit.setLocale(Locale(code));
      },
      dropdownMenuEntries: [
        DropdownMenuEntry(value: 'en', label: l10n.languageEnglish),
        DropdownMenuEntry(value: 'ar', label: l10n.languageArabic),
      ],
    );
  }
}
