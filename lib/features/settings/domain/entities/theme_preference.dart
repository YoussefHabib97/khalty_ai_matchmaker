/// The user's chosen app theme.
enum ThemePreference {
  deviceDefault,
  light,
  dark;

  /// Parses a stored value, falling back to [deviceDefault].
  static ThemePreference fromName(Object? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => deviceDefault);
}
