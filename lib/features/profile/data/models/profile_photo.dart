import 'package:khalty_ai_matchmaker/core/utils/json_dates.dart';

/// One of the user's photos. Local-only for now; a storage path/URL is
/// added when uploads arrive with Firebase.
class ProfilePhoto {
  const ProfilePhoto({
    required this.id,
    required this.localPath,
    required this.addedAt,
  });

  factory ProfilePhoto.fromJson(Map<String, Object?> json) => ProfilePhoto(
    id: json['id'] as String,
    localPath: json['localPath'] as String,
    addedAt: dateFromJson(json['addedAt']),
  );

  final String id;
  final String localPath;
  final DateTime addedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'localPath': localPath,
    'addedAt': dateToJson(addedAt),
  };

  @override
  bool operator ==(Object other) =>
      other is ProfilePhoto &&
      other.id == id &&
      other.localPath == localPath &&
      other.addedAt == addedAt;
  @override
  int get hashCode => Object.hash(id, localPath, addedAt);
}
