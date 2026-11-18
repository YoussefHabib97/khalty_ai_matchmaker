import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:material_ui/material_ui.dart';

/// A faceless figure in a circle, used instead of a photo: beard styles for
/// men, hijab or niqab for women. No eyes or facial features are ever drawn.
/// Shapes ported from the old app's `silhouette.dart`; colours follow the
/// theme so it works in light and dark mode.
class Silhouette extends StatelessWidget {
  const Silhouette({
    super.key,
    required this.gender,
    required this.style,
    this.size = 96,
  });

  final Gender gender;
  final SilhouetteStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.tertiaryContainer],
          ),
        ),
        child: ClipOval(
          child: CustomPaint(
            size: Size.square(size),
            painter: _SilhouettePainter(
              gender: gender,
              style: style,
              figure: colors.primary.withValues(alpha: 0.8),
              face: colors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({
    required this.gender,
    required this.style,
    required this.figure,
    required this.face,
  });

  final Gender gender;
  final SilhouetteStyle style;
  final Color figure;
  final Color face;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 100×100 grid.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fig = Paint()..color = figure;
    final skin = Paint()..color = face;

    Path p(void Function(Path) draw) {
      final path = Path();
      draw(path);
      return path..close();
    }

    if (gender == Gender.male) {
      // Shoulders, neck, face, short hair.
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(10, 100)
            ..cubicTo(12, 80, 30, 74, 50, 74)
            ..cubicTo(70, 74, 88, 80, 90, 100),
        ),
        fig,
      );
      canvas.drawRect(const Rect.fromLTWH(44, 56, 12, 20), skin);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 43), width: 29, height: 36),
        skin,
      );
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(35.5, 42)
            ..quadraticBezierTo(34, 23, 50, 23)
            ..quadraticBezierTo(66, 23, 64.5, 42)
            ..quadraticBezierTo(60, 31, 50, 31.5)
            ..quadraticBezierTo(40, 31, 35.5, 42),
        ),
        fig,
      );
      if (style == SilhouetteStyle.fullBeard) {
        canvas.drawPath(
          p(
            (x) => x
              ..moveTo(35.6, 44)
              ..quadraticBezierTo(36.5, 66, 50, 66)
              ..quadraticBezierTo(63.5, 66, 64.4, 44)
              ..quadraticBezierTo(59, 55, 50, 55)
              ..quadraticBezierTo(41, 55, 35.6, 44),
          ),
          fig,
        );
      } else if (style == SilhouetteStyle.trimmedBeard) {
        canvas.drawPath(
          p(
            (x) => x
              ..moveTo(36, 47)
              ..quadraticBezierTo(38, 63, 50, 63)
              ..quadraticBezierTo(62, 63, 64, 47)
              ..quadraticBezierTo(60, 58.5, 50, 59)
              ..quadraticBezierTo(40, 58.5, 36, 47),
          ),
          fig,
        );
      }
    } else if (style == SilhouetteStyle.plain) {
      // Long hair behind, shoulders, neck, face, fringe.
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(31, 38)
            ..cubicTo(28, 58, 27, 74, 30, 84)
            ..lineTo(70, 84)
            ..cubicTo(73, 74, 72, 58, 69, 38),
        ),
        fig,
      );
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(18, 100)
            ..cubicTo(20, 83, 33, 77, 50, 77)
            ..cubicTo(67, 77, 80, 83, 82, 100),
        ),
        fig,
      );
      canvas.drawRect(const Rect.fromLTWH(45, 58, 10, 18), skin);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 44), width: 26, height: 33),
        skin,
      );
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(36, 44)
            ..quadraticBezierTo(33, 24, 50, 23)
            ..quadraticBezierTo(67, 24, 64, 44)
            ..quadraticBezierTo(61, 32, 50, 31)
            ..quadraticBezierTo(39, 32, 36, 44),
        ),
        fig,
      );
    } else {
      // Head scarf flowing over the shoulders.
      canvas.drawPath(
        p(
          (x) => x
            ..moveTo(31, 42)
            ..cubicTo(26, 62, 16, 78, 12, 100)
            ..lineTo(88, 100)
            ..cubicTo(84, 78, 74, 62, 69, 42),
        ),
        fig,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 40), width: 38, height: 44),
        fig,
      );
      if (style == SilhouetteStyle.niqab) {
        // Face covered: only a soft band where the eyes would be.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(39, 37, 22, 6),
            const Radius.circular(3),
          ),
          skin,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 44), width: 23, height: 29),
          skin,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      old.gender != gender ||
      old.style != style ||
      old.figure != figure ||
      old.face != face;
}
