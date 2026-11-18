import 'dart:io';

import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/silhouette.dart';
import 'package:material_ui/material_ui.dart';

/// The main photo in a circle, or the faceless silhouette when there is no
/// photo (or it can't be read).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.gender,
    required this.silhouette,
    this.photoPath,
    this.size = 96,
  });

  final Gender gender;
  final SilhouetteStyle silhouette;
  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Silhouette(gender: gender, style: silhouette, size: size);
    final path = photoPath;
    if (path == null) return fallback;
    return ClipOval(
      child: Image.file(
        File(path),
        key: const Key('profilePhoto'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
