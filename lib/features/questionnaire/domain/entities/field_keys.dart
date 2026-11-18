/// Keys of the questionnaire fields that code depends on directly. Everything
/// else is driven by the config file. A test checks each key exists there.
abstract final class FieldKeys {
  static const name = 'name';
  static const age = 'age';
  static const country = 'country';
  static const city = 'city';
  static const heightCm = 'height_cm';
  static const nationality = 'nationality';
  static const hijab = 'hijab';
  static const beard = 'beard';
  static const partnerAge = 'partner_age';

  static const all = [
    name,
    age,
    country,
    city,
    heightCm,
    nationality,
    hijab,
    beard,
    partnerAge,
  ];
}
