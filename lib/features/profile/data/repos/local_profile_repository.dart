import 'dart:async';
import 'dart:convert';

import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/user_profile_mapper.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';

/// Keeps the profile on the device as versioned JSON (see
/// [UserProfileMapper]).
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._prefs) {
    _current = _load();
  }

  static const key = 'profile.v1';

  /// Where an unreadable profile is copied, so nothing is silently lost.
  static const corruptKey = 'profile.v1.corrupt';

  final SharedPrefs _prefs;
  final _changes = StreamController<UserProfile?>.broadcast();
  UserProfile? _current;

  @override
  UserProfile? get current => _current;

  @override
  Stream<UserProfile?> watch() => _changes.stream;

  @override
  Future<void> save(UserProfile profile) async {
    await _prefs.setData(
      key: key,
      value: jsonEncode(UserProfileMapper.toJson(profile)),
    );
    _set(profile);
  }

  @override
  Future<void> clear() async {
    await _prefs.removeData(key: key);
    _set(null);
  }

  /// Closes the change stream (called when the service locator is reset).
  Future<void> dispose() => _changes.close();

  void _set(UserProfile? profile) {
    _current = profile;
    _changes.add(profile);
  }

  UserProfile? _load() {
    final raw = _prefs.getData(key: key);
    if (raw is! String) return null;
    try {
      return UserProfileMapper.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      // Back it up and start fresh rather than crash or delete it.
      _prefs.setData(key: corruptKey, value: raw);
      _prefs.removeData(key: key);
      return null;
    }
  }
}
