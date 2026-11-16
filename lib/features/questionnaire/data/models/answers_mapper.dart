import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';

/// Converts [Answers] to and from their stored JSON form:
/// `{ "<field key>": <AnswerValue JSON>, ... }`.
abstract final class AnswersMapper {
  static Map<String, Object?> toJson(Answers answers) => {
    for (final MapEntry(:key, :value) in answers.entries) key: value.toJson(),
  };

  /// Entries that can't be parsed are dropped, so the user is simply asked
  /// that question again instead of the app failing.
  static Answers fromJson(Object? json) {
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
}
