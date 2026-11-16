import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answer_value.dart';

/// The answers the user actually gave, keyed by field key. Immutable.
///
/// Derived values (a field's `else_value` / `else_from`, or not-applicable)
/// are never stored here; the questionnaire engine computes them on read,
/// so they can't go stale when an earlier answer changes.
class Answers {
  Answers([Map<String, AnswerValue> values = const {}])
    : _values = Map.unmodifiable(values) {
    if (values.values.any((v) => v is NotApplicable)) {
      throw ArgumentError('NotApplicable is derived and cannot be stored');
    }
  }

  /// Parses persisted answers. Entries that can't be parsed are dropped, so
  /// the user is simply asked that question again instead of the app failing.
  factory Answers.fromJson(Object? json) {
    if (json is! Map) return Answers();
    final values = <String, AnswerValue>{};
    for (final MapEntry(:key, :value) in json.entries) {
      try {
        values[key as String] = AnswerValue.fromJson(value);
      } on FormatException {
        // Dropped on purpose; see above.
      }
    }
    return Answers(values);
  }

  final Map<String, AnswerValue> _values;

  AnswerValue? operator [](String key) => _values[key];
  bool has(String key) => _values.containsKey(key);
  Iterable<String> get keys => _values.keys;
  int get length => _values.length;
  bool get isEmpty => _values.isEmpty;

  /// Returns a copy with [key] set to [value].
  Answers set(String key, AnswerValue value) =>
      Answers({..._values, key: value});

  /// Returns a copy without [key].
  Answers remove(String key) => Answers({..._values}..remove(key));

  Map<String, Object?> toJson() => {
    for (final MapEntry(:key, :value) in _values.entries) key: value.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is Answers &&
      other._values.length == _values.length &&
      _values.entries.every((e) => other._values[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(
    _values.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'Answers($_values)';
}
