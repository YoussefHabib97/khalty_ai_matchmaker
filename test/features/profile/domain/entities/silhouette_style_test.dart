import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';

import '../../../../helpers/questionnaire.dart';

void main() {
  test('men: beard styles', () {
    expect(
      SilhouetteStyle.of(Gender.male, 'full_beard'),
      SilhouetteStyle.fullBeard,
    );
    expect(
      SilhouetteStyle.of(Gender.male, 'trimmed_beard'),
      SilhouetteStyle.trimmedBeard,
    );
    expect(SilhouetteStyle.of(Gender.male, 'no_beard'), SilhouetteStyle.plain);
    expect(SilhouetteStyle.of(Gender.male, null), SilhouetteStyle.plain);
  });

  test('women: hijab and niqab ("sometimes" shows a hijab)', () {
    expect(SilhouetteStyle.of(Gender.female, 'niqab'), SilhouetteStyle.niqab);
    expect(SilhouetteStyle.of(Gender.female, 'hijab'), SilhouetteStyle.hijab);
    expect(
      SilhouetteStyle.of(Gender.female, 'hijab_sometimes'),
      SilhouetteStyle.hijab,
    );
    expect(
      SilhouetteStyle.of(Gender.female, 'no_hijab'),
      SilhouetteStyle.plain,
    );
    expect(SilhouetteStyle.of(Gender.female, null), SilhouetteStyle.plain);
  });

  test('another gender\'s option never applies', () {
    expect(SilhouetteStyle.of(Gender.male, 'niqab'), SilhouetteStyle.plain);
    expect(
      SilhouetteStyle.of(Gender.female, 'full_beard'),
      SilhouetteStyle.plain,
    );
  });

  test('every beard and hijab option id in the config is known', () {
    final config = loadRealConfig();
    final known = {
      'full_beard', 'trimmed_beard', 'no_beard', //
      'niqab', 'hijab', 'hijab_sometimes', 'no_hijab',
    };
    for (final key in ['beard', 'hijab']) {
      for (final option in config.field(key)!.options) {
        expect(known, contains(option.id), reason: '$key: ${option.id}');
      }
    }
  });
}
