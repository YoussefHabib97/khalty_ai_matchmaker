import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/country_search.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the country picker; returns the chosen country, or null if closed.
/// [title] replaces the default "Choose a country".
Future<Country?> showCountryPicker(BuildContext context, {String? title}) =>
    showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CountryPickerSheet(title: title),
    );

/// Searchable list of countries: common ones first, then all, in the app
/// language. Shared by sign-up (dialling code) and country questions.
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, this.title});

  final String? title;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final searching = _query.trim().isNotEmpty;
    final results = searching ? searchCountries(_query, language) : null;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.title ?? l10n.chooseCountry,
              style: context.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.countrySearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: switch (results) {
              null => ListView(
                children: [
                  _Header(l10n.countriesCommon),
                  for (final c in commonCountries()) _CountryTile(c),
                  const Divider(),
                  _Header(l10n.countriesAll),
                  for (final c in countriesSortedFor(language)) _CountryTile(c),
                ],
              ),
              [] => Center(child: Text(l10n.countriesNoResults)),
              final list => ListView(
                children: [for (final c in list) _CountryTile(c)],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
    child: Text(text, style: context.labelLarge),
  );
}

class _CountryTile extends StatelessWidget {
  const _CountryTile(this.country);

  final Country country;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
    title: Text(country.name(context.appLanguage)),
    trailing: Text('+${country.dialCode}', textDirection: TextDirection.ltr),
    onTap: () => Navigator.of(context).pop(country),
  );
}
