/// A signed-in account.
class AuthUser {
  const AuthUser({required this.uid, required this.phoneE164});

  final String uid;

  /// Verified phone number in international format, e.g. `+966501234567`.
  final String phoneE164;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.uid == uid && other.phoneE164 == phoneE164;
  @override
  int get hashCode => Object.hash(uid, phoneE164);
  @override
  String toString() => 'AuthUser($uid, $phoneE164)';
}
