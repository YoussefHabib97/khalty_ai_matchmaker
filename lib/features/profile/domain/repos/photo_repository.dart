import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';

/// Where a new photo comes from.
enum PhotoSource { gallery, camera }

/// The user's photo files. Today copies kept in the app's own folder; later
/// uploads to Firebase Storage. The list of photos itself is part of the
/// `UserProfile`.
abstract interface class PhotoRepository {
  /// Lets the user pick or take a photo and keeps a resized copy. Null when
  /// they cancel.
  Future<ProfilePhoto?> add(PhotoSource source);

  /// Deletes the photo's file (the caller removes it from the profile).
  Future<void> delete(ProfilePhoto photo);

  /// The file path to show [photo] from.
  String pathOf(ProfilePhoto photo);
}
