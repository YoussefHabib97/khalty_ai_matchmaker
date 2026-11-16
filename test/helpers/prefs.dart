import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [SharedPrefs] backed by in-memory mock storage seeded with [values].
Future<SharedPrefs> mockPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPrefs(await SharedPreferences.getInstance());
}
