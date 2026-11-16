/// A problem in the questionnaire config file. [path] points at the exact
/// place, e.g. `fields[7].options[2].label.ar`.
class ConfigException implements Exception {
  const ConfigException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'Questionnaire config error at $path: $message';
}
