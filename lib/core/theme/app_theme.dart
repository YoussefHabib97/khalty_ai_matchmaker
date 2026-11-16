import 'package:khalty_ai_matchmaker/core/theme/app_colors.dart';
import 'package:khalty_ai_matchmaker/core/theme/text_theme.dart';
import 'package:material_ui/material_ui.dart';

abstract class AppTheme {
  // Getters (not cached finals) so ScreenUtil-scaled text sizes are
  // recomputed on each build, e.g. after a screen size change.
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: AppColors.seed,
    ),
    brightness: brightness,
    textTheme: buildTextTheme(),
    useMaterial3: true,
  );
}
