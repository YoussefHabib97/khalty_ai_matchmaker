import 'package:khalty_ai_matchmaker/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

abstract class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: AppColors.seed,
    ),
    brightness: brightness,
    useMaterial3: true,
  );
}
