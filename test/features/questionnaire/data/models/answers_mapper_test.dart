import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answers_mapper.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';

void main() {
  test('round-trips through JSON', () {
    final answers = Answers({
      'name': const TextAnswer('Sara'),
      'partner_age': RangeAnswer(28, 35),
      'languages': MultiAnswer(['arabic', 'english']),
    });
    final json = jsonDecode(jsonEncode(AnswersMapper.toJson(answers)));
    expect(AnswersMapper.fromJson(json), answers);
  });

  test('drops entries that cannot be parsed instead of failing', () {
    final back = AnswersMapper.fromJson({
      'name': {'t': 'text', 'v': 'Ali'},
      'age': {'t': 'number', 'v': 'twenty'},
      'old': {'t': 'legacy_string'},
    });
    expect(back.keys, ['name']);
  });

  test('anything that is not an object gives empty answers', () {
    expect(AnswersMapper.fromJson(null).isEmpty, isTrue);
    expect(AnswersMapper.fromJson('oops').isEmpty, isTrue);
  });
}
