import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';

/// The signed-in user's own profile. Today stored on the device; later in
/// Firestore.
abstract interface class ProfileRepository {
  /// The saved profile, available synchronously at startup.
  UserProfile? get current;

  /// Emits on every save or clear (not the current value; read [current]).
  Stream<UserProfile?> watch();

  Future<void> save(UserProfile profile);
  Future<void> clear();
}
