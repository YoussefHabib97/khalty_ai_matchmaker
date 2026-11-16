import 'package:khalty_ai_matchmaker/core/utils/collections.dart';

/// A typed answer to one questionnaire field.
///
/// Persisted as `{"t": <type>, "v": <value>}`. Choice values are stable
/// option ids from the questionnaire config (e.g. `never_married`), never
/// display labels, so rewording an option never breaks stored answers.
sealed class AnswerValue {
  const AnswerValue();

  /// Parses a persisted answer. Throws [FormatException] for unknown types or
  /// malformed values (including [NotApplicable], which is never persisted).
  factory AnswerValue.fromJson(Object? json) {
    if (json is! Map) throw FormatException('Answer is not an object: $json');
    final v = json['v'];
    try {
      return switch (json['t']) {
        TextAnswer.type => TextAnswer(v as String),
        NumberAnswer.type => NumberAnswer((v as num).toInt()),
        ChoiceAnswer.type => ChoiceAnswer(v as String),
        MultiAnswer.type => MultiAnswer(
          List<String>.from((v as Map)['ids'] as List),
          custom: List<String>.from(v['custom'] as List? ?? const []),
        ),
        RangeAnswer.type => RangeAnswer(
          ((v as Map)['min'] as num).toInt(),
          (v['max'] as num).toInt(),
        ),
        CountryAnswer.type => CountryAnswer(v as String),
        NoneAnswer.type => const NoneAnswer(),
        SkippedAnswer.type => const SkippedAnswer(),
        final t => throw FormatException('Unknown answer type: $t'),
      };
    } on TypeError catch (e) {
      throw FormatException('Malformed ${json['t']} answer: $v ($e)');
    } on ArgumentError catch (e) {
      throw FormatException('Invalid ${json['t']} answer: $v (${e.message})');
    }
  }

  Map<String, Object?> toJson();
}

/// Free text (e.g. name, city, job).
final class TextAnswer extends AnswerValue {
  const TextAnswer(this.text);
  static const type = 'text';
  final String text;

  @override
  Map<String, Object?> toJson() => {'t': type, 'v': text};

  @override
  bool operator ==(Object other) => other is TextAnswer && other.text == text;
  @override
  int get hashCode => Object.hash(type, text);
  @override
  String toString() => 'TextAnswer($text)';
}

/// A whole number (e.g. age, height in cm).
final class NumberAnswer extends AnswerValue {
  const NumberAnswer(this.value);
  static const type = 'number';
  final int value;

  @override
  Map<String, Object?> toJson() => {'t': type, 'v': value};

  @override
  bool operator ==(Object other) =>
      other is NumberAnswer && other.value == value;
  @override
  int get hashCode => Object.hash(type, value);
  @override
  String toString() => 'NumberAnswer($value)';
}

/// One option, by id.
final class ChoiceAnswer extends AnswerValue {
  const ChoiceAnswer(this.optionId);
  static const type = 'choice';
  final String optionId;

  @override
  Map<String, Object?> toJson() => {'t': type, 'v': optionId};

  @override
  bool operator ==(Object other) =>
      other is ChoiceAnswer && other.optionId == optionId;
  @override
  int get hashCode => Object.hash(type, optionId);
  @override
  String toString() => 'ChoiceAnswer($optionId)';
}

/// Several options by id, plus any free-text entries the user added
/// (only for fields that allow it). Kept as lists, never joined strings.
final class MultiAnswer extends AnswerValue {
  MultiAnswer(List<String> optionIds, {List<String> custom = const []})
    : optionIds = List.unmodifiable(optionIds),
      custom = List.unmodifiable(custom);
  static const type = 'multi';
  final List<String> optionIds;
  final List<String> custom;

  int get count => optionIds.length + custom.length;

  @override
  Map<String, Object?> toJson() => {
    't': type,
    'v': {'ids': optionIds, 'custom': custom},
  };

  @override
  bool operator ==(Object other) =>
      other is MultiAnswer &&
      listEquals(other.optionIds, optionIds) &&
      listEquals(other.custom, custom);
  @override
  int get hashCode =>
      Object.hash(type, Object.hashAll(optionIds), Object.hashAll(custom));
  @override
  String toString() => 'MultiAnswer($optionIds, custom: $custom)';
}

/// An inclusive range (e.g. partner age 25–32).
final class RangeAnswer extends AnswerValue {
  RangeAnswer(this.min, this.max) {
    if (min > max) throw ArgumentError('min ($min) must be <= max ($max)');
  }
  static const type = 'range';
  final int min;
  final int max;

  @override
  Map<String, Object?> toJson() => {
    't': type,
    'v': {'min': min, 'max': max},
  };

  @override
  bool operator ==(Object other) =>
      other is RangeAnswer && other.min == min && other.max == max;
  @override
  int get hashCode => Object.hash(type, min, max);
  @override
  String toString() => 'RangeAnswer($min-$max)';
}

/// A country by ISO 3166-1 alpha-2 code (e.g. `SA`), stored upper-case.
final class CountryAnswer extends AnswerValue {
  CountryAnswer(String iso2) : iso2 = iso2.toUpperCase() {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(this.iso2)) {
      throw ArgumentError('Not an ISO2 country code: $iso2');
    }
  }
  static const type = 'country';
  final String iso2;

  @override
  Map<String, Object?> toJson() => {'t': type, 'v': iso2};

  @override
  bool operator ==(Object other) =>
      other is CountryAnswer && other.iso2 == iso2;
  @override
  int get hashCode => Object.hash(type, iso2);
  @override
  String toString() => 'CountryAnswer($iso2)';
}

/// An explicit "No" / "None" (e.g. no second nationality).
final class NoneAnswer extends AnswerValue {
  const NoneAnswer();
  static const type = 'none';

  @override
  Map<String, Object?> toJson() => const {'t': type};

  @override
  bool operator ==(Object other) => other is NoneAnswer;
  @override
  int get hashCode => type.hashCode;
  @override
  String toString() => 'NoneAnswer()';
}

/// An optional field the user chose to skip (e.g. height, sect).
final class SkippedAnswer extends AnswerValue {
  const SkippedAnswer();
  static const type = 'skipped';

  @override
  Map<String, Object?> toJson() => const {'t': type};

  @override
  bool operator ==(Object other) => other is SkippedAnswer;
  @override
  int get hashCode => type.hashCode;
  @override
  String toString() => 'SkippedAnswer()';
}

/// The field doesn't apply to this user (its condition isn't met). Only ever
/// derived by the questionnaire engine; never stored or persisted.
final class NotApplicable extends AnswerValue {
  const NotApplicable();

  @override
  Map<String, Object?> toJson() =>
      throw UnsupportedError('NotApplicable is derived and never persisted');

  @override
  bool operator ==(Object other) => other is NotApplicable;
  @override
  int get hashCode => (NotApplicable).hashCode;
  @override
  String toString() => 'NotApplicable()';
}
