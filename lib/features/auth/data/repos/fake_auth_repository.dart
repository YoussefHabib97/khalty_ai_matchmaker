import 'dart:async';
import 'dart:convert';

import 'package:khalty_ai_matchmaker/core/utils/ids.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_failure.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/otp_request.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';

/// Local stand-in for SMS sign-in until Firebase is added. The code is always
/// [code]. Like Firebase, the same phone number always gets the same uid, and
/// the session survives restarts.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(
    this._prefs, {
    this.delay = const Duration(milliseconds: 800),
  }) : _user = _load(_prefs);

  /// The only code accepted.
  static const code = '123456';
  static const sessionKey = 'auth.session.v1';

  final SharedPrefs _prefs;

  /// Simulated network delay (zero in tests).
  final Duration delay;

  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  @override
  Future<OtpRequest> sendCode(String phoneE164) async {
    await Future<void>.delayed(delay);
    return OtpRequest(
      phoneE164: phoneE164,
      verificationId: newId(),
      sentAt: DateTime.now(),
    );
  }

  @override
  Future<AuthUser> verifyCode(OtpRequest request, String code) async {
    await Future<void>.delayed(delay);
    if (code.trim() != FakeAuthRepository.code) {
      throw const AuthException(AuthFailure.invalidCode);
    }
    final digits = request.phoneE164.replaceAll(RegExp(r'\D'), '');
    final user = AuthUser(uid: 'fake-$digits', phoneE164: request.phoneE164);
    await _prefs.setData(
      key: sessionKey,
      value: jsonEncode({'uid': user.uid, 'phone': user.phoneE164}),
    );
    _set(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _prefs.removeData(key: sessionKey);
    _set(null);
  }

  @override
  Future<void> deleteAccount() => signOut();

  /// Closes the change stream (called when the service locator is reset).
  Future<void> dispose() => _changes.close();

  void _set(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }

  static AuthUser? _load(SharedPrefs prefs) {
    final raw = prefs.getData(key: sessionKey);
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw) as Map;
      return AuthUser(
        uid: json['uid'] as String,
        phoneE164: json['phone'] as String,
      );
    } on Object {
      return null; // Unreadable session: treat as signed out.
    }
  }
}
