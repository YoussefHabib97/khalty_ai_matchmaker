import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';

void main() {
  late Directory documents;
  late Directory pickerFolder;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('documents');
    pickerFolder = await Directory.systemTemp.createTemp('picker');
  });
  tearDown(() async {
    await documents.delete(recursive: true);
    await pickerFolder.delete(recursive: true);
  });

  LocalPhotoRepository repo(_FakePicker picker) => LocalPhotoRepository(
    documents.path,
    picker: picker,
    now: () => DateTime.utc(2026, 11, 18),
  );

  test('a picked photo is copied in and stored by a relative path', () async {
    final picked = File('${pickerFolder.path}/IMG_1.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final picker = _FakePicker(picked.path);
    final photos = repo(picker);

    final photo = await photos.add(PhotoSource.camera);
    expect(picker.lastSource, ImageSource.camera);
    expect(picker.lastMaxWidth, LocalPhotoRepository.maxSide);
    expect(photo!.localPath, 'photos/${photo.id}.jpg');
    expect(photos.pathOf(photo), '${documents.path}/photos/${photo.id}.jpg');
    expect(File(photos.pathOf(photo)).readAsBytesSync(), [1, 2, 3]);

    await photos.delete(photo);
    expect(File(photos.pathOf(photo)).existsSync(), isFalse);
  });

  test('closing the picker adds nothing', () async {
    expect(await repo(_FakePicker(null)).add(PhotoSource.gallery), isNull);
  });
}

/// An image picker that "picks" [path] (or nothing).
class _FakePicker extends ImagePicker {
  _FakePicker(this.path);

  final String? path;
  ImageSource? lastSource;
  double? lastMaxWidth;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    lastMaxWidth = maxWidth;
    return path == null ? null : XFile(path!);
  }
}
