import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/cubit/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LocaleCubit>();
    return SegmentedButton<String>(
      showSelectedIcon: false,
      selected: {cubit.state.languageCode},
      onSelectionChanged: (selection) =>
          cubit.setLocale(Locale(selection.first)),
      segments: [
        ButtonSegment(value: 'en', label: Text(context.l10n.languageEnglish)),
        ButtonSegment(value: 'ar', label: Text(context.l10n.languageArabic)),
      ],
    );
  }
}
