import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';

/// Photos without a picker or files: each [add] returns a new photo (or
/// null when [cancel] is set); [deleted] records deletions.
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository({DateTime? now})
    : _now = now ?? DateTime.utc(2026, 11, 18, 9);

  final DateTime _now;
  final deleted = <ProfilePhoto>[];
  var _count = 0;

  /// The next [add] behaves as if the user closed the picker.
  bool cancel = false;

  /// The next [add] fails.
  bool fail = false;

  @override
  Future<ProfilePhoto?> add(PhotoSource source) async {
    if (fail) throw Exception('picker failed');
    if (cancel) return null;
    _count++;
    return ProfilePhoto(
      id: 'photo$_count',
      localPath: 'photos/photo$_count.jpg',
      addedAt: _now,
    );
  }

  @override
  Future<void> delete(ProfilePhoto photo) async => deleted.add(photo);

  @override
  String pathOf(ProfilePhoto photo) => '/fake/${photo.localPath}';
}
