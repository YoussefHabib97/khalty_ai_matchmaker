import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:khalty_ai_matchmaker/core/utils/ids.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Photos picked with the system picker or camera, resized and copied into
/// the app's documents folder under `photos/`. Paths are stored relative to
/// that folder (see [ProfilePhoto]). Create with [LocalPhotoRepository.open].
class LocalPhotoRepository implements PhotoRepository {
  LocalPhotoRepository(
    this._documents, {
    ImagePicker? picker,
    DateTime Function()? now,
  }) : _picker = picker ?? ImagePicker(),
       _now = now ?? DateTime.now;

  /// Finds the documents folder once (it is needed synchronously by
  /// [pathOf]). Falls back to the temp folder where the platform has none
  /// (widget tests).
  static Future<LocalPhotoRepository> open() async {
    try {
      return LocalPhotoRepository(
        (await getApplicationDocumentsDirectory()).path,
      );
    } on Exception {
      return LocalPhotoRepository(Directory.systemTemp.path);
    }
  }

  /// Longest side kept, in pixels; enough for a full-screen photo.
  static const maxSide = 1440.0;

  final String _documents;
  final ImagePicker _picker;
  final DateTime Function() _now;

  @override
  Future<ProfilePhoto?> add(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final id = newId();
    final relative = 'photos/$id.jpg';
    final file = File('$_documents/$relative');
    await file.parent.create(recursive: true);
    await File(picked.path).copy(file.path);
    return ProfilePhoto(id: id, localPath: relative, addedAt: _now());
  }

  @override
  Future<void> delete(ProfilePhoto photo) async {
    final file = File(pathOf(photo));
    if (await file.exists()) await file.delete();
  }

  @override
  String pathOf(ProfilePhoto photo) => '$_documents/${photo.localPath}';
}
