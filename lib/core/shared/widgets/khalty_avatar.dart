import 'package:material_ui/material_ui.dart';

/// Khalty's picture. An icon stands in for her artwork until designs arrive.
class KhaltyAvatar extends StatelessWidget {
  const KhaltyAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: Icon(
        Icons.auto_awesome,
        size: radius,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}
