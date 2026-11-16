import 'package:flutter/services.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Country (flag + dialling code) button and the phone number. Always laid
/// out left-to-right, as phone numbers are, even in Arabic.
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    required this.country,
    required this.initialValue,
    required this.onCountryTap,
    required this.onChanged,
    this.errorText,
  });

  final Country country;
  final String initialValue;
  final VoidCallback onCountryTap;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        OutlinedButton(
          key: const Key('countryButton'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: widget.onCountryTap,
          child: Text('${widget.country.flag}  +${widget.country.dialCode}'),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              // ASCII and Arabic digits, plus common separators.
              FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹ ()+\\-.]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.phoneLabel,
              errorText: widget.errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    ),
  );
}
