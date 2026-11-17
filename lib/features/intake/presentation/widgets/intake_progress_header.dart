import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Under the app bar: "Chapter 2 of 5", questions left and a progress bar.
class IntakeProgressHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const IntakeProgressHeader({
    super.key,
    required this.chapter,
    required this.chapterCount,
    required this.remaining,
    required this.fraction,
  });

  final int chapter;
  final int chapterCount;
  final int remaining;

  /// 0.0–1.0.
  final double fraction;

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Row(
            children: [
              Text(
                l10n.intakeChapterOf(chapter, chapterCount),
                style: context.labelLarge,
              ),
              const Spacer(),
              Text(
                l10n.intakeQuestionsLeft(remaining),
                style: context.labelLarge,
              ),
            ],
          ),
          LinearProgressIndicator(
            value: fraction,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
