import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences]. Registered as a singleton in the
/// service locator and injected wherever local key/value storage is needed.
class SharedPrefs {
  SharedPrefs(this._prefs) {
    _checkIsAppFirstRun();
  }

  final SharedPreferences _prefs;

  static const String kIsAppFirstRunKey = 'appIsFirstRun';
  late final bool isAppFirstRun;

  Future<bool> setData({required String key, required dynamic value}) async {
    if (value is int) {
      await _prefs.setInt(key, value);
      return true;
    }
    if (value is double) {
      await _prefs.setDouble(key, value);
      return true;
    }
    if (value is bool) {
      await _prefs.setBool(key, value);
      return true;
    }
    if (value is String) {
      await _prefs.setString(key, value);
      return true;
    }
    if (value is List<String>) {
      await _prefs.setStringList(key, value);
      return true;
    }
    return false;
  }

  dynamic getData({required String key}) => _prefs.get(key);

  Future<bool> removeData({required String key}) => _prefs.remove(key);

  Future<bool> clearPrefs() => _prefs.clear();

  /// `true` only on the very first launch; the flag is then stored as `false`.
  /// (A stored `true` comes from older builds that never cleared the flag and
  /// is treated as a first run once.)
  void _checkIsAppFirstRun() {
    isAppFirstRun = _prefs.get(kIsAppFirstRunKey) != false;
    if (isAppFirstRun) {
      setData(key: kIsAppFirstRunKey, value: false);
      setData(key: kAppThemeKey, value: kAppThemeDeviceDefault);
    }
  }
}
