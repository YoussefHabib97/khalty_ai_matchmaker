/// Dates are persisted as ISO-8601 strings in UTC.
String dateToJson(DateTime date) => date.toUtc().toIso8601String();

String? nullableDateToJson(DateTime? date) =>
    date == null ? null : dateToJson(date);

/// Parses a persisted date; throws [FormatException] if missing or invalid.
DateTime dateFromJson(Object? json) {
  if (json is! String) throw FormatException('Expected a date string: $json');
  return DateTime.parse(json);
}

DateTime? nullableDateFromJson(Object? json) =>
    json == null ? null : dateFromJson(json);
