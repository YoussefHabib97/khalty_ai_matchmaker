import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/otp_request.dart';

/// Phone-number sign-in. Today a fake; later Firebase phone auth.
abstract interface class AuthRepository {
  /// The signed-in user, available synchronously at startup.
  AuthUser? get currentUser;

  /// Emits whenever the signed-in user changes (not the current value; read
  /// [currentUser] for that).
  Stream<AuthUser?> authStateChanges();

  /// Sends a one-time code by SMS.
  Future<OtpRequest> sendCode(String phoneE164);

  /// Signs in with the code; throws `AuthException` if it is wrong.
  Future<AuthUser> verifyCode(OtpRequest request, String code);

  Future<void> signOut();
  Future<void> deleteAccount();
}
