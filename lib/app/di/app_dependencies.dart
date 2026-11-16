import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';

/// Builds every long-lived service once, at startup, and hands them to
/// [ApplicationRoot]. Repositories are added here as they are introduced;
/// switching from local/fake implementations to Firebase ones happens in
/// [create] without touching the UI.
class AppDependencies {
  const AppDependencies._();

  static Future<AppDependencies> create() async {
    await SharedPrefs.init();
    return const AppDependencies._();
  }
}
