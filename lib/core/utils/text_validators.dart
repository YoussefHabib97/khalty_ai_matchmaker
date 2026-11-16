final _personName = RegExp(
  r"^[a-zA-Z\p{L} ,.'-]*$",
  caseSensitive: false,
  unicode: true,
);

/// Letters (any script), spaces and `,.'-` only. Pure Dart, so the domain
/// layer can use it.
bool isValidPersonName(String value) => _personName.hasMatch(value);
