import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// "Why this question?": Khalty's reason for asking, in a bottom sheet.
Future<void> showWhyQuestionSheet(BuildContext context, String reason) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 8,
                children: [
                  const Icon(Icons.lightbulb_outline),
                  Text(
                    context.l10n.intakeWhyThisQuestion,
                    style: context.titleLarge,
                  ),
                ],
              ),
              Text(reason, style: context.bodyLarge),
            ],
          ),
        ),
      ),
    );
