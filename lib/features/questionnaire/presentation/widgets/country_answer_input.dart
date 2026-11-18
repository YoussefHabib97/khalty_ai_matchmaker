import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/country_picker_sheet.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/option_card.dart';
import 'package:material_ui/material_ui.dart';

/// A country question. Two forms:
///
/// - **confirm** ("Are you living in Saudi Arabia?"): the [suggested]
///   country with **Yes**, or **No, another country** to pick one.
/// - **optional** ([optional], "Do you have a second nationality?"): **No**,
///   or **Yes** to pick one (showing the chosen country once answered).
class CountryAnswerInput extends StatelessWidget {
  const CountryAnswerInput({
    super.key,
    required this.onCountry,
    required this.pickTitle,
    this.suggested,
    this.optional = false,
    this.onNone,
    this.noneSelected = false,
    this.enabled = true,
  });

  /// Confirm form: the country to confirm. Optional form: the earlier
  /// answer, if any.
  final Country? suggested;
  final bool optional;

  /// Called with the chosen country's ISO code.
  final ValueChanged<String> onCountry;

  /// Optional form: "No".
  final VoidCallback? onNone;

  /// Optional form: the earlier answer was "No".
  final bool noneSelected;

  /// Title of the country list (the question's `question_pick`).
  final String pickTitle;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final country = await showCountryPicker(context, title: pickTitle);
    if (country != null) onCountry(country.iso2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final country = suggested;

    if (optional) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          OptionCard(
            key: const Key('countryNone'),
            label: l10n.answerNo,
            selected: noneSelected,
            onTap: enabled ? onNone : null,
          ),
          OptionCard(
            key: const Key('countryPick'),
            label: country == null
                ? l10n.countryYesChoose
                : l10n.countryYesChosen(country.name(language)),
            leading: country == null ? null : _Flag(country),
            selected: country != null,
            onTap: enabled ? () => _pick(context) : null,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (country != null)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 12,
                children: [
                  _Flag(country, size: 32),
                  Expanded(
                    child: Text(
                      country.name(language),
                      style: context.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (country != null)
          FilledButton(
            key: const Key('countryYes'),
            onPressed: enabled ? () => onCountry(country.iso2) : null,
            child: Text(l10n.answerYes),
          ),
        OutlinedButton(
          key: const Key('countryOther'),
          onPressed: enabled ? () => _pick(context) : null,
          child: Text(
            country == null ? l10n.chooseCountry : l10n.countryNoOther,
          ),
        ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.country, {this.size = 24});

  final Country country;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(country.flag, style: TextStyle(fontSize: size));
}
