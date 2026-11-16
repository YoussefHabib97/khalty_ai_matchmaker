import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/entities/theme_preference.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

class ThemeSwitcherWidget extends StatelessWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppThemeCubit>();
    return SegmentedButton<ThemePreference>(
      selected: {cubit.state},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => cubit.setTheme(selection.first),
      segments: const [
        ButtonSegment(
          tooltip: 'Light Theme',
          icon: Icon(Icons.light_mode_rounded),
          value: ThemePreference.light,
        ),
        ButtonSegment(
          tooltip: 'System Default',
          icon: Icon(Icons.phone_android_rounded),
          value: ThemePreference.deviceDefault,
        ),
        ButtonSegment(
          tooltip: 'Dark Theme',
          icon: Icon(Icons.dark_mode_rounded),
          value: ThemePreference.dark,
        ),
      ],
    );
  }
}
