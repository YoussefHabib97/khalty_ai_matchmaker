import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

/// Light · System · Dark.
class ThemeSwitcherWidget extends StatelessWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppThemeCubit>();
    final l10n = context.l10n;
    return SegmentedButton<ThemePreference>(
      selected: {cubit.state},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => cubit.setTheme(selection.first),
      segments: [
        ButtonSegment(
          icon: const Icon(Icons.light_mode_rounded),
          label: Text(l10n.themeLight),
          value: ThemePreference.light,
        ),
        ButtonSegment(
          icon: const Icon(Icons.phone_android_rounded),
          label: Text(l10n.themeSystem),
          value: ThemePreference.deviceDefault,
        ),
        ButtonSegment(
          icon: const Icon(Icons.dark_mode_rounded),
          label: Text(l10n.themeDark),
          value: ThemePreference.dark,
        ),
      ],
    );
  }
}
