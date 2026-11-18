import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Edits the "About me" text. Returns the new text, or null when cancelled.
/// Leaving with unsaved changes asks first.
Future<String?> showAboutMeSheet(
  BuildContext context, {
  required String text,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // Closing goes through the buttons or Back, which can ask first.
  isDismissible: false,
  enableDrag: false,
  builder: (_) => _AboutMeSheet(initial: text),
);

class _AboutMeSheet extends StatefulWidget {
  const _AboutMeSheet({required this.initial});

  final String initial;

  @override
  State<_AboutMeSheet> createState() => _AboutMeSheetState();
}

class _AboutMeSheetState extends State<_AboutMeSheet> {
  /// Longest bio accepted.
  static const maxLength = 600;

  late final _text = TextEditingController(text: widget.initial);

  bool get _changed => _text.text.trim() != widget.initial.trim();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (!_changed || await _confirmDiscard()) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            key: const Key('confirmDiscard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(l10n.meAboutMe, style: context.titleLarge),
            TextField(
              key: const Key('aboutMeField'),
              controller: _text,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              maxLength: maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.aboutMeHint,
                border: const OutlineInputBorder(),
              ),
            ),
            Row(
              children: [
                TextButton(
                  key: const Key('aboutMeCancel'),
                  onPressed: _leave,
                  child: Text(l10n.cancel),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('aboutMeSave'),
                  onPressed: () => Navigator.of(context).pop(_text.text),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
