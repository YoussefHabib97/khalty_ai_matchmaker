import 'package:flutter/services.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';
import 'package:material_ui/material_ui.dart';

/// A typed answer: free text (name, city, job) or a whole number (age,
/// height). Numbers accept Western, Arabic-Indic and Persian digits.
class TypedAnswerInput extends StatelessWidget {
  const TypedAnswerInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.numeric = false,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool numeric;
  final VoidCallback onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      inputFormatters: numeric
          ? [
              FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹]')),
              LengthLimitingTextInputFormatter(3),
            ]
          : [
              LengthLimitingTextInputFormatter(
                QuestionnaireEngine.maxTextLength,
              ),
            ],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: errorText,
        errorMaxLines: 3,
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
