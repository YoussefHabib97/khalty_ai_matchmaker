import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/search_text.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';
import 'package:material_ui/material_ui.dart';

/// Several answers: a chip per option, plus the user's own entries when
/// [allowText]. With [maxPick], the remaining chips are disabled once the
/// limit is reached, so there is never a silent cut-off. The parent keeps
/// the draft and gets every change through [onChanged].
class MultiAnswerInput extends StatefulWidget {
  const MultiAnswerInput({
    super.key,
    required this.options,
    required this.language,
    required this.gender,
    required this.selectedIds,
    required this.custom,
    required this.onChanged,
    this.maxPick,
    this.allowText = false,
    this.enabled = true,
  });

  /// The options this user may pick (already gender-filtered).
  final List<OptionDef> options;
  final AppLanguage language;
  final Gender gender;
  final List<String> selectedIds;

  /// The user's own entries.
  final List<String> custom;
  final void Function(List<String> ids, List<String> custom) onChanged;
  final int? maxPick;
  final bool allowText;
  final bool enabled;

  @override
  State<MultiAnswerInput> createState() => _MultiAnswerInputState();
}

class _MultiAnswerInputState extends State<MultiAnswerInput> {
  final _own = TextEditingController();

  int get _count => widget.selectedIds.length + widget.custom.length;
  bool get _full => widget.maxPick != null && _count >= widget.maxPick!;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    final ids = [...widget.selectedIds];
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    widget.onChanged(ids, widget.custom);
  }

  /// Adds the typed entry. If it matches an option (in either language), the
  /// option is picked instead; duplicates are ignored.
  void _addOwn() {
    final text = _own.text.trim();
    if (text.isEmpty || _full) return;
    _own.clear();
    final key = normalizeForSearch(text);
    for (final option in widget.options) {
      final labels = [
        for (final language in AppLanguage.values)
          normalizeForSearch(option.label.resolve(language, widget.gender)),
      ];
      if (labels.contains(key)) {
        if (!widget.selectedIds.contains(option.id)) _toggle(option.id);
        return;
      }
    }
    if (widget.custom.any((c) => normalizeForSearch(c) == key)) return;
    widget.onChanged(widget.selectedIds, [...widget.custom, text]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final max = widget.maxPick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (max != null)
          Text(
            l10n.multiPickUpTo(max, max - _count),
            style: context.bodyMedium,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in widget.options)
              FilterChip(
                key: Key('option-${option.id}'),
                label: Text(
                  option.label.resolve(widget.language, widget.gender),
                ),
                selected: widget.selectedIds.contains(option.id),
                onSelected:
                    widget.enabled &&
                        (widget.selectedIds.contains(option.id) || !_full)
                    ? (_) => _toggle(option.id)
                    : null,
              ),
            for (final entry in widget.custom)
              InputChip(
                label: Text(entry),
                selected: true,
                onDeleted: widget.enabled
                    ? () => widget.onChanged(widget.selectedIds, [
                        ...widget.custom.where((c) => c != entry),
                      ])
                    : null,
              ),
          ],
        ),
        if (widget.allowText)
          TextField(
            key: const Key('multiOwn'),
            controller: _own,
            enabled: widget.enabled && !_full,
            maxLength: QuestionnaireEngine.maxTextLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.multiAddOwn,
              border: const OutlineInputBorder(),
              counterText: '',
              suffixIcon: IconButton(
                key: const Key('multiOwnAdd'),
                icon: const Icon(Icons.add),
                tooltip: l10n.multiAddOwn,
                onPressed: widget.enabled ? _addOwn : null,
              ),
            ),
            onSubmitted: (_) => _addOwn(),
          ),
      ],
    );
  }
}
