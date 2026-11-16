/// Why signing in failed. The UI turns each reason into a message.
enum AuthFailure { invalidCode, codeExpired, tooManyAttempts, network }

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}
