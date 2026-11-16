import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';

import '../../../../helpers/profile_fixtures.dart';

void main() {
  test('derived getters', () {
    final p = fullProfile();
    expect(p.name, 'Sara');
    expect(p.age, 27);
    expect(p.mainPhoto?.id, 'p1');
    expect(p.effectiveAboutMe, 'I am Sara.');
    expect(p.copyWith(aboutMe: 'Edited').effectiveAboutMe, 'Edited');
    expect(minimalProfile().name, isNull);
    expect(minimalProfile().mainPhoto, isNull);
  });

  test('copyWith can clear nullable fields explicitly', () {
    final cleared = fullProfile().copyWith(analysis: null, selfIntro: null);
    expect(cleared.analysis, isNull);
    expect(cleared.selfIntro, isNull);
    expect(cleared.answers, fullProfile().answers); // untouched
    expect(fullProfile().copyWith(), fullProfile()); // nothing passed
  });

  test('enforces the photo and trait limits', () {
    final photo = ProfilePhoto(
      id: 'p',
      localPath: '/p.jpg',
      addedAt: fixtureTime,
    );
    expect(
      () => minimalProfile().copyWith(photos: List.filled(4, photo)),
      throwsArgumentError,
    );
    expect(
      () => IntakeAnalysis(
        aboutMe: '',
        traits: List.filled(5, const Trait(label: 'a', reason: 'b')),
        brief: '',
        language: AppLanguage.en,
        generatedAt: fixtureTime,
      ),
      throwsArgumentError,
    );
  });
}
