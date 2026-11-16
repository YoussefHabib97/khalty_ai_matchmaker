import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';

/// Encodes to a JSON string and back, as persistence does.
AnswerValue roundTrip(AnswerValue v) =>
    AnswerValue.fromJson(jsonDecode(jsonEncode(v.toJson())));

void main() {
  group('AnswerValue', () {
    final samples = <AnswerValue>[
      const TextAnswer('Riyadh'),
      const NumberAnswer(29),
      const ChoiceAnswer('never_married'),
      MultiAnswer(['kind', 'religious'], custom: ['Bad temper, honestly']),
      MultiAnswer(['arabic']),
      RangeAnswer(25, 32),
      CountryAnswer('sa'),
      const NoneAnswer(),
      const SkippedAnswer(),
    ];

    for (final sample in samples) {
      test('round-trips ${sample.runtimeType}', () {
        expect(roundTrip(sample), sample);
      });
    }

    test('multi-select custom text containing commas stays one entry', () {
      final back =
          roundTrip(MultiAnswer([], custom: ['a, b, c'])) as MultiAnswer;
      expect(back.custom, ['a, b, c']);
      expect(back.count, 1);
    });

    test('country codes are stored upper-case and validated', () {
      expect(CountryAnswer('ae').iso2, 'AE');
      expect(() => CountryAnswer('UAE'), throwsArgumentError);
    });

    test('range rejects min greater than max', () {
      expect(() => RangeAnswer(40, 30), throwsArgumentError);
      expect(
        () => AnswerValue.fromJson({
          't': 'range',
          'v': {'min': 40, 'max': 30},
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown types and malformed values', () {
      expect(
        () => AnswerValue.fromJson({'t': 'mystery', 'v': 1}),
        throwsFormatException,
      );
      expect(
        () => AnswerValue.fromJson({'t': 'number', 'v': 'abc'}),
        throwsFormatException,
      );
      expect(() => AnswerValue.fromJson('text'), throwsFormatException);
    });

    test('NotApplicable is never persisted', () {
      expect(() => const NotApplicable().toJson(), throwsUnsupportedError);
      expect(
        () => AnswerValue.fromJson({'t': 'not_applicable'}),
        throwsFormatException,
      );
    });
  });

  group('Answers', () {
    test('is immutable: set/remove return copies', () {
      final a = Answers();
      final b = a.set('age', const NumberAnswer(29));
      expect(a.isEmpty, isTrue);
      expect(b['age'], const NumberAnswer(29));
      expect(b.remove('age').has('age'), isFalse);
      expect(b.has('age'), isTrue);
    });

    test('refuses to store NotApplicable', () {
      expect(
        () => Answers().set('prayer', const NotApplicable()),
        throwsArgumentError,
      );
    });
  });
}
