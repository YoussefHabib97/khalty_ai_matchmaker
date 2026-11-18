/// One of the user's photos. Local-only for now; a storage path/URL is
/// added when uploads arrive with Firebase.
///
/// [localPath] is **relative** to the app's documents folder (e.g.
/// `photos/<id>.jpg`), because that folder's absolute path can change
/// between app updates on iOS. `PhotoRepository.pathOf` resolves it.
class ProfilePhoto {
  const ProfilePhoto({
    required this.id,
    required this.localPath,
    required this.addedAt,
  });

  final String id;
  final String localPath;
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      other is ProfilePhoto &&
      other.id == id &&
      other.localPath == localPath &&
      other.addedAt == addedAt;
  @override
  int get hashCode => Object.hash(id, localPath, addedAt);
}
