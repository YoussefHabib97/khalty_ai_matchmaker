import 'dart:io';

import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:material_ui/material_ui.dart';

/// The photo slots ([UserProfile.maxPhotos]): the first is the main photo.
/// An empty slot offers gallery or camera; a photo offers "make main" and
/// delete.
class PhotoSlots extends StatelessWidget {
  const PhotoSlots({
    super.key,
    required this.photos,
    required this.pathOf,
    required this.onAdd,
    required this.onMakeMain,
    required this.onDelete,
    this.enabled = true,
  });

  final List<ProfilePhoto> photos;
  final String Function(ProfilePhoto) pathOf;
  final ValueChanged<PhotoSource> onAdd;
  final ValueChanged<ProfilePhoto> onMakeMain;
  final ValueChanged<ProfilePhoto> onDelete;
  final bool enabled;

  Future<void> _addMenu(BuildContext context) async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('photoFromGallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoFromGallery),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.photoFromCamera),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) onAdd(source);
  }

  Future<void> _photoMenu(BuildContext context, ProfilePhoto photo) async {
    final l10n = context.l10n;
    final isMain = photos.first.id == photo.id;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMain)
              ListTile(
                key: const Key('photoMakeMain'),
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.photoMakeMain),
                onTap: () {
                  Navigator.of(context).pop();
                  onMakeMain(photo);
                },
              ),
            ListTile(
              key: const Key('photoDelete'),
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.photoDelete),
              onTap: () {
                Navigator.of(context).pop();
                onDelete(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Row(
      spacing: 12,
      children: [
        for (var i = 0; i < UserProfile.maxPhotos; i++)
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: i < photos.length
                  ? _PhotoTile(
                      key: Key('photo-$i'),
                      path: pathOf(photos[i]),
                      isMain: i == 0,
                      mainLabel: l10n.photoMain,
                      onTap: enabled
                          ? () => _photoMenu(context, photos[i])
                          : null,
                    )
                  : Material(
                      key: Key('photoSlot-$i'),
                      color: colors.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        // Only the next free slot adds, so order stays tidy.
                        onTap: enabled && i == photos.length
                            ? () => _addMenu(context)
                            : null,
                        child: Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            semanticLabel: l10n.photoAdd,
                            color: i == photos.length
                                ? colors.primary
                                : colors.outline,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.path,
    required this.isMain,
    required this.mainLabel,
    required this.onTap,
  });

  final String path;
  final bool isMain;
  final String mainLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.broken_image_outlined, color: colors.outline),
            ),
            if (isMain)
              PositionedDirectional(
                top: 6,
                start: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      mainLabel,
                      style: context.labelSmall.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
