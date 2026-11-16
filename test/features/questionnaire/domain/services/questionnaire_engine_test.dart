import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/digits.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

import '../../../../helpers/questionnaire.dart';

void main() {
  final config = loadRealConfig();
  final man = QuestionnaireEngine(config, Gender.male);
  final woman = QuestionnaireEngine(config, Gender.female);

  FieldDef field(String key) => config.field(key)!;
  InvalidReason? reason(QuestionnaireEngine e, String key, AnswerValue v) =>
      e.validate(field(key), v).reason;
  Answers answers(Map<String, AnswerValue> values) => Answers(values);

  group('gender', () {
    test('each gender gets its own questions', () {
      final menKeys = man.fields.map((f) => f.key);
      final womenKeys = woman.fields.map((f) => f.key);
      expect(menKeys, containsAll(['beard', 'partner_hijab']));
      expect(menKeys, isNot(contains('hijab')));
      expect(womenKeys, containsAll(['hijab', 'open_to_second_wife']));
      expect(womenKeys, isNot(contains('beard')));
      expect(man.fields, hasLength(31));
      expect(woman.fields, hasLength(31));
    });

    test('each gender only sees its own options', () {
      const seeking = ChoiceAnswer('married_seeking_additional');
      expect(reason(man, 'marital_status', seeking), isNull);
      expect(
        reason(woman, 'marital_status', seeking),
        InvalidReason.unknownOption,
      );
      expect(
        reason(man, 'must_haves', MultiAnswer(['ambitious'])),
        InvalidReason.unknownOption,
      );
    });
  });

  group('derived answers', () {
    test('never married: children is not asked and becomes "no children"', () {
      final a = answers({
        'marital_status': const ChoiceAnswer('never_married'),
      });
      expect(man.applies(field('children_now'), a), isFalse);
      expect(
        man.effective('children_now', a),
        const EffectiveAnswer(
          ChoiceAnswer('no_children'),
          sourceKey: 'children_now',
          derived: true,
        ),
      );
    });

    test('divorced: children is asked and has no answer yet', () {
      final a = answers({'marital_status': const ChoiceAnswer('divorced')});
      expect(man.applies(field('children_now'), a), isTrue);
      expect(man.effective('children_now', a), isNull);
    });

    test('studying: work is taken from employment, with its labels', () {
      final a = answers({'employment': const ChoiceAnswer('studying')});
      expect(man.applies(field('work'), a), isFalse);
      expect(
        man.effective('work', a),
        const EffectiveAnswer(
          ChoiceAnswer('studying'),
          sourceKey: 'employment',
          derived: true,
        ),
      );
    });

    test('working: work is asked', () {
      final a = answers({'employment': const ChoiceAnswer('working')});
      expect(man.applies(field('work'), a), isTrue);
    });

    test('praying sometimes: prayer and beard do not apply', () {
      final a = answers({
        'religious_commitment': const ChoiceAnswer('pray_sometimes'),
      });
      expect(man.effective('prayer', a)?.value, const NotApplicable());
      expect(man.applies(field('beard'), a), isFalse);
      expect(
        woman.applies(field('hijab'), a),
        isTrue,
      ); // only "not practising" skips it
    });

    test('a stored answer stays hidden while its question does not apply', () {
      final a = answers({
        'religious_commitment': const ChoiceAnswer('not_practising'),
        'prayer': const ChoiceAnswer('always_masjid'),
      });
      expect(man.effective('prayer', a)?.value, const NotApplicable());
    });

    test('changing an answer brings a question back', () {
      final done = fillAll(
        man,
        overrides: {'marital_status': const ChoiceAnswer('never_married')},
      );
      expect(man.nextField(done), isNull);

      final edited = man.apply(
        done,
        'marital_status',
        const ChoiceAnswer('divorced'),
      );
      expect(man.missingAnswers(edited).map((f) => f.key), ['children_now']);
      expect(man.nextField(edited)?.key, 'children_now');
    });
  });

  group('navigation', () {
    test('starts with the name, then follows the config order', () {
      expect(man.nextField(Answers())?.key, 'name');
      final a = man.apply(Answers(), 'name', const TextAnswer('Ali'));
      expect(man.nextField(a)?.key, 'age');
    });

    test('resumes at the first unanswered question', () {
      var a = Answers();
      for (var i = 0; i < 5; i++) {
        final next = man.nextField(a)!;
        a = man.apply(a, next.key, defaultAnswer(man, next, a));
      }
      expect(man.nextField(a), man.fields[5]);
    });

    test('an answer whose option no longer exists is asked again', () {
      final complete = fillAll(man);
      final stale = complete.set('education', const ChoiceAnswer('old_id'));
      expect(man.nextField(stale)?.key, 'education');
    });

    test('Back skips questions that do not apply', () {
      final a = answers({
        'marital_status': const ChoiceAnswer('never_married'),
      });
      expect(man.previousField('education', a)?.key, 'marital_status');
      final b = answers({'marital_status': const ChoiceAnswer('divorced')});
      expect(man.previousField('education', b)?.key, 'children_now');
    });

    test('Back from the end and from the first question', () {
      final done = fillAll(man);
      expect(man.previousField(null, done), man.fields.last);
      expect(man.previousField('name', done), isNull);
      expect(() => man.previousField('hijab', done), throwsArgumentError);
    });
  });

  group('validation', () {
    test('text: not blank, not too long, names are letters only', () {
      expect(reason(man, 'city', const TextAnswer('  ')), InvalidReason.empty);
      expect(reason(man, 'city', TextAnswer('a' * 101)), InvalidReason.tooLong);
      expect(
        reason(man, 'name', const TextAnswer('Ali99')),
        InvalidReason.invalidName,
      );
      expect(reason(man, 'name', const TextAnswer('سارة')), isNull);
      expect(reason(man, 'name', const TextAnswer("Mary-Jane O'Neil")), isNull);
    });

    test('number: within bounds, typed in any digits', () {
      expect(
        reason(man, 'age', const NumberAnswer(17)),
        InvalidReason.outOfRange,
      );
      expect(reason(man, 'age', const NumberAnswer(18)), isNull);
      expect(reason(man, 'age', const NumberAnswer(80)), isNull);
      expect(
        reason(man, 'age', const NumberAnswer(81)),
        InvalidReason.outOfRange,
      );
      expect(
        reason(man, 'age', NumberAnswer(parseLocalizedInt('٢٩')!)),
        isNull,
      );
    });

    test('range: both ends within bounds', () {
      expect(reason(man, 'partner_age', RangeAnswer(18, 80)), isNull);
      expect(
        reason(man, 'partner_age', RangeAnswer(17, 30)),
        InvalidReason.outOfRange,
      );
    });

    test('multi: limits, duplicates and typed entries', () {
      expect(
        reason(
          man,
          'must_haves',
          MultiAnswer(['religious', 'kind', 'educated']),
        ),
        isNull,
      );
      expect(
        reason(
          man,
          'must_haves',
          MultiAnswer(['religious', 'kind', 'educated', 'beautiful']),
        ),
        InvalidReason.tooManyPicks,
      );
      expect(
        reason(man, 'must_haves', MultiAnswer(['kind', 'kind'])),
        InvalidReason.duplicateOption,
      );
      expect(reason(man, 'must_haves', MultiAnswer([])), InvalidReason.empty);
      expect(
        reason(man, 'must_haves', MultiAnswer([], custom: ['Funny'])),
        InvalidReason.customNotAllowed,
      );
      expect(
        reason(man, 'deal_breakers', MultiAnswer([], custom: ['Lying, a lot'])),
        isNull,
      );
      expect(
        reason(man, 'deal_breakers', MultiAnswer([], custom: ['  '])),
        InvalidReason.empty,
      );
    });

    test('country questions', () {
      expect(reason(man, 'country', CountryAnswer('SA')), isNull);
      expect(
        reason(man, 'country', const NoneAnswer()),
        InvalidReason.wrongType,
      );
      expect(reason(man, 'second_nationality', const NoneAnswer()), isNull);
      expect(reason(man, 'second_nationality', CountryAnswer('EG')), isNull);
    });

    test('skipping only works on optional questions', () {
      expect(reason(man, 'height_cm', const SkippedAnswer()), isNull);
      expect(
        reason(man, 'age', const SkippedAnswer()),
        InvalidReason.notOptional,
      );
    });

    test('the answer type must match the question', () {
      expect(
        reason(man, 'age', const TextAnswer('29')),
        InvalidReason.wrongType,
      );
      expect(
        reason(man, 'education', const TextAnswer('Bachelor')),
        InvalidReason.wrongType,
      );
    });

    test('apply trims text, and rejects invalid or foreign answers', () {
      final a = man.apply(Answers(), 'city', const TextAnswer('  Riyadh '));
      expect(a['city'], const TextAnswer('Riyadh'));
      expect(
        () => man.apply(Answers(), 'age', const NumberAnswer(10)),
        throwsA(isA<InvalidAnswerException>()),
      );
      expect(
        () => man.apply(Answers(), 'hijab', const ChoiceAnswer('hijab')),
        throwsArgumentError,
      );
    });
  });

  group('progress', () {
    test('starts at zero in chapter 1, counting every question', () {
      final p = man.progress(Answers());
      expect(p.answered, 0);
      expect(p.total, man.fields.length);
      expect(p.chapter, 1);
      expect(p.chapterCount, 5);
      expect(p.fraction, 0);
    });

    for (final engine in [man, woman]) {
      test('reaches 100% for a ${engine.gender.name}, and the count only goes '
          'down', () {
        var lastRemaining = engine.progress(Answers()).remaining;
        final done = fillAll(
          engine,
          onStep: (a) {
            final remaining = engine.progress(a).remaining;
            expect(remaining, lessThan(lastRemaining));
            lastRemaining = remaining;
          },
        );
        final p = engine.progress(done);
        expect(p.isComplete, isTrue);
        expect(p.fraction, 1);
        expect(p.chapter, 5);
        expect(engine.nextField(done), isNull);
      });
    }

    test('questions that stop applying leave the total', () {
      final never = answers({
        'marital_status': const ChoiceAnswer('never_married'),
      });
      final divorced = answers({
        'marital_status': const ChoiceAnswer('divorced'),
      });
      expect(man.progress(never).total, man.progress(divorced).total - 1);
    });
  });

  group('suggested partner age', () {
    RangeAnswer? suggest(QuestionnaireEngine e, int age) =>
        e.suggestedRange('partner_age', answers({'age': NumberAnswer(age)}));

    test('starts from the user\'s age, kept within 18-80', () {
      expect(suggest(man, 30), RangeAnswer(22, 31));
      expect(suggest(man, 18), RangeAnswer(18, 19));
      expect(suggest(woman, 30), RangeAnswer(29, 38));
      expect(suggest(woman, 78), RangeAnswer(77, 80));
    });

    test('is null without an age', () {
      expect(man.suggestedRange('partner_age', Answers()), isNull);
    });
  });

  group('AI payload', () {
    test('uses English labels and leaves out what does not apply', () {
      final done = fillAll(
        man,
        overrides: {
          'religious_commitment': const ChoiceAnswer('pray_sometimes'),
          'employment': const ChoiceAnswer('studying'),
          'height_cm': const SkippedAnswer(),
          'deal_breakers': MultiAnswer(['smoking'], custom: ['Lying']),
        },
      );
      final payload = man.toAiPayload(done);
      expect(payload['marital_status'], 'Never married');
      expect(payload['children_now'], 'No children'); // derived
      expect(payload['work'], 'Studying'); // from employment
      expect(payload['deal_breakers'], ['Smoking', 'Lying']);
      expect(payload['country'], 'SA');
      expect(payload['second_nationality'], 'None');
      expect(payload['partner_age'], {'min': 22, 'max': 31});
      expect(payload.containsKey('prayer'), isFalse); // not applicable
      expect(payload.containsKey('height_cm'), isFalse); // skipped
      expect(payload.containsKey('hijab'), isFalse); // not asked to men
    });
  });
}
