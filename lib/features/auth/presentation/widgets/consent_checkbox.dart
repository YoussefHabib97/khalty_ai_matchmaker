import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// The sign-up agreement (Khalty's presence in conversations, privacy).
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: (checked) => onChanged(checked ?? false),
    controlAffinity: ListTileControlAffinity.leading,
    contentPadding: EdgeInsets.zero,
    title: Text(context.l10n.consentText),
    subtitle: errorText == null
        ? null
        : Text(
            errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
  );
}
