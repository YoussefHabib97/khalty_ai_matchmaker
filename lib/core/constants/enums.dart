/// The user's gender. Drives gendered Arabic texts and gender-specific
/// questions. Persisted by [name].
enum Gender {
  male,
  female;

  /// Parses a persisted value; throws [FormatException] if unknown.
  static Gender fromName(Object? name) => values.firstWhere(
    (g) => g.name == name,
    orElse: () => throw FormatException('Unknown gender: $name'),
  );
}

/// Languages the app supports. Persisted by [name] (the language code).
enum AppLanguage {
  en,
  ar;

  String get code => name;

  /// Parses a language code, falling back to English.
  static AppLanguage fromCode(Object? code) =>
      values.firstWhere((l) => l.name == code, orElse: () => en);
}
