import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/questionnaire_config_parser.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/config_exception.dart';

Map<String, Object?> t(String en, [Object? ar]) => {'en': en, 'ar': ar ?? en};

/// A small but complete valid config; each test breaks one thing.
Map<String, dynamic> validConfig() => jsonDecode(
  jsonEncode({
    'schema_version': 2,
    'chapters': [
      {'id': 1, 'title': t('About you')},
      {'id': 2, 'title': t('Spouse'), 'intro': t('Now about your spouse')},
    ],
    'fields': [
      {
        'key': 'name',
        'chapter': 1,
        'input': 'text',
        'visibility': 'card',
        'question': t('Your name?'),
        'why': t('So I can call you by name, {name}.'),
      },
      {
        'key': 'age',
        'chapter': 1,
        'input': 'number',
        'visibility': 'card',
        'min': 18,
        'max': 80,
        'question': t('Age?'),
        'why': t('Why'),
      },
      {
        'key': 'status',
        'chapter': 1,
        'input': 'choice',
        'visibility': 'card',
        'question': t('Status?', {'male': 'm', 'female': 'f'}),
        'why': t('Why'),
        'options': [
          {'id': 'never', 'label': t('Never married')},
          {'id': 'divorced', 'label': t('Divorced')},
          {'id': 'seeking', 'gender': 'male', 'label': t('Seeking')},
        ],
      },
      {
        'key': 'kids',
        'chapter': 1,
        'input': 'choice',
        'visibility': 'card',
        'question': t('Children?'),
        'why': t('Why'),
        'options': [
          {'id': 'none', 'label': t('None')},
          {'id': 'some', 'label': t('Some')},
        ],
        'if': {
          'field': 'status',
          'not_in': ['never'],
        },
        'else_value': 'none',
      },
      {
        'key': 'country',
        'chapter': 1,
        'input': 'country',
        'visibility': 'card',
        'question': t('Living in {detected}?'),
        'question_pick': t('Which country?'),
        'why': t('Why'),
      },
      {
        'key': 'partner_age',
        'chapter': 2,
        'input': 'range',
        'visibility': 'khalty',
        'min': 18,
        'max': 80,
        'suggest': {
          'male': [-8, 1],
          'female': [-1, 8],
        },
        'question': t('Age range?'),
        'why': t('Why'),
      },
      {
        'key': 'picks',
        'chapter': 2,
        'input': 'multi',
        'visibility': 'khalty',
        'max_pick': 2,
        'allow_text': true,
        'question': t('Pick up to 2'),
        'why': t('Why'),
        'needs_review': ['ar'],
        'options': [
          {'id': 'a', 'label': t('A')},
          {'id': 'b', 'label': t('B')},
          {'id': 'c', 'label': t('C')},
        ],
      },
    ],
    'script': {
      'greeting': t('Hello'),
      'acks': {
        'en': ['Thanks {name}'],
        'ar': ['شكرًا'],
      },
      'name_ack': t('Nice to meet you, {name}'),
      'self_intro': t('Tell me about you', {'male': 'm', 'female': 'f'}),
      'analysing': t('One moment'),
    },
  }),
);

Map<String, dynamic> field(Map<String, dynamic> json, String key) =>
    (json['fields'] as List).cast<Map<String, dynamic>>().firstWhere(
      (f) => f['key'] == key,
    );

void expectError(Map<String, dynamic> json, String path, String message) {
  expect(
    () => const QuestionnaireConfigParser().parse(json),
    throwsA(
      isA<ConfigException>()
          .having((e) => e.path, 'path', contains(path))
          .having((e) => e.message, 'message', contains(message)),
    ),
  );
}

void main() {
  test('the valid sample parses', () {
    final config = const QuestionnaireConfigParser().parse(validConfig());
    expect(config.fields, hasLength(7));
    final kids = config.field('kids')!;
    expect(kids.condition!.isMetBy('divorced'), isTrue);
    expect(kids.condition!.isMetBy('never'), isFalse);
    expect(kids.elseValue, 'none');
    expect(config.field('partner_age')!.suggest.length, 2);
    expect(config.chapter(2).intro, isNotNull);
  });

  group('rejects', () {
    test('an unsupported schema version', () {
      expectError(validConfig()..['schema_version'] = 1, 'schema_version', '2');
    });

    test('a duplicate key', () {
      final json = validConfig();
      field(json, 'age')['key'] = 'name';
      expectError(json, 'fields[1].key', 'duplicate');
    });

    test('a chapter that does not exist', () {
      final json = validConfig();
      field(json, 'age')['chapter'] = 9;
      expectError(json, '("age").chapter', 'does not exist');
    });

    test('a choice question without options', () {
      final json = validConfig();
      field(json, 'kids').remove('options');
      expectError(json, '("kids").options', 'expected a list');
    });

    test('options on a non-choice question', () {
      final json = validConfig();
      field(json, 'name')['options'] = [];
      expectError(json, '("name").options', 'only choice/multi');
    });

    test('a missing Arabic text', () {
      final json = validConfig();
      (field(json, 'age')['question'] as Map).remove('ar');
      expectError(json, '("age").question.ar', 'missing text');
    });

    test('a gendered text missing one version', () {
      final json = validConfig();
      field(json, 'status')['question'] = t('Status?', {'male': 'm'});
      expectError(json, '("status").question.ar.female', 'missing text');
    });

    test('an unknown placeholder', () {
      final json = validConfig();
      field(json, 'name')['why'] = t('Hello {nmae}');
      expectError(json, '("name").why.en', '{nmae}');
    });

    test('a condition on a later question', () {
      final json = validConfig();
      field(json, 'kids')['if'] = {
        'field': 'picks',
        'in': ['a'],
      };
      expectError(json, '("kids").if.field', 'earlier question');
    });

    test('a condition with an unknown option id', () {
      final json = validConfig();
      field(json, 'kids')['if'] = {
        'field': 'status',
        'in': ['Never married'],
      };
      expectError(json, '("kids").if.in[0]', 'not an option of "status"');
    });

    test('an else_value that is not an option id', () {
      final json = validConfig();
      field(json, 'kids')['else_value'] = 'No children';
      expectError(json, '("kids").else_value', 'not one of');
    });

    test('min not below max', () {
      final json = validConfig();
      field(json, 'age')['min'] = 80;
      expectError(json, '("age").min', 'must be below max');
    });

    test('max_pick larger than the number of options', () {
      final json = validConfig();
      field(json, 'picks')['max_pick'] = 5;
      expectError(json, '("picks").max_pick', 'between 1 and');
    });

    test('an invalid visibility', () {
      final json = validConfig();
      field(json, 'age')['visibility'] = 'public';
      expectError(json, '("age").visibility', 'card, khalty');
    });

    test('a country question without question_pick', () {
      final json = validConfig();
      field(json, 'country').remove('question_pick');
      expectError(json, '("country").question_pick', 'expected {"en"');
    });

    test('a misspelled property name', () {
      final json = validConfig();
      field(json, 'age')['visiblity'] = 'card';
      expectError(json, '("age").visiblity', 'unknown property');
    });

    test('gender-only options that leave a gender with none', () {
      final json = validConfig();
      for (final o in field(json, 'kids')['options'] as List) {
        (o as Map)['gender'] = 'male';
      }
      expectError(json, '("kids").options', 'no options for female');
    });

    test('a missing script line', () {
      final json = validConfig();
      (json['script'] as Map).remove('greeting');
      expectError(json, 'script.greeting', 'expected {"en"');
    });
  });
}
