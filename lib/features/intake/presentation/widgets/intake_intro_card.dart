import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/khalty_avatar.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// A pause between questions: Khalty's greeting, or a chapter's intro.
class IntakeIntroCard extends StatelessWidget {
  const IntakeIntroCard({
    super.key,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
    this.title,
  });

  /// Chapter title (none for the greeting).
  final String? title;

  /// Khalty's line.
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: DefaultPadding(
          child: Column(
            spacing: 16,
            children: [
              const KhaltyAvatar(radius: 40),
              if (title != null)
                Text(
                  title!,
                  style: context.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              Text(text, style: context.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
