import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:material_ui/material_ui.dart';

/// A range of whole years (partner age): the chosen range in large text over
/// a two-handle slider bounded by the question's [min]–[max].
class RangeAnswerInput extends StatelessWidget {
  const RangeAnswerInput({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });

  final RangeAnswer value;
  final int min;
  final int max;
  final ValueChanged<RangeAnswer> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Text(
          context.l10n.rangeYears(value.min, value.max),
          style: context.headlineSmall,
        ),
        RangeSlider(
          values: RangeValues(value.min.toDouble(), value.max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          labels: RangeLabels('${value.min}', '${value.max}'),
          onChanged: enabled
              ? (v) => onChanged(RangeAnswer(v.start.round(), v.end.round()))
              : null,
        ),
      ],
    );
  }
}
