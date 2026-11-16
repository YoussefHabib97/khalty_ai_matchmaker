import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answers.dart';

final _t = DateTime.utc(2026, 11, 16, 10);

UserProfile _minimal() => UserProfile(
  uid: 'u1',
  gender: Gender.female,
  phoneE164: '+966501234567',
  consent: Consent(version: 1, acceptedAt: _t),
);

UserProfile _full() => _minimal().copyWith(
  answers: Answers({
    'name': const TextAnswer('Sara'),
    'age': const NumberAnswer(27),
  }),
  selfIntro: SelfIntro.typed('I love books.', at: _t),
  analysis: IntakeAnalysis(
    aboutMe: 'I am Sara.',
    traits: const [Trait(label: 'Kind', reason: 'Mentions family often')],
    brief: 'Sara is 27.',
    mismatches: const ['Mentions shisha, answered No to smoking'],
    language: AppLanguage.ar,
    generatedAt: _t,
  ),
  photos: [ProfilePhoto(id: 'p1', localPath: '/x/p1.jpg', addedAt: _t)],
  sharePhotoWithMatch: true,
  progress: OnboardingProgress(intakeDoneAt: _t, selfIntroDoneAt: _t),
);

UserProfile _roundTrip(UserProfile p) => UserProfile.fromJson(
  Map<String, Object?>.from(jsonDecode(jsonEncode(p.toJson())) as Map),
);

void main() {
  test('round-trips a minimal and a full profile through JSON', () {
    expect(_roundTrip(_minimal()), _minimal());
    expect(_roundTrip(_full()), _full());
  });

  test('persists enums by name and includes the schema version', () {
    final json = _full().toJson();
    expect(json['schema'], UserProfile.schemaVersion);
    expect(json['gender'], 'female');
    expect((json['analysis'] as Map)['language'], 'ar');
  });

  test('derived getters', () {
    final p = _full();
    expect(p.name, 'Sara');
    expect(p.age, 27);
    expect(p.mainPhoto?.id, 'p1');
    expect(p.effectiveAboutMe, 'I am Sara.');
    expect(p.copyWith(aboutMe: 'Edited').effectiveAboutMe, 'Edited');
    expect(_minimal().name, isNull);
  });

  test('copyWith can clear nullable fields explicitly', () {
    final cleared = _full().copyWith(analysis: null, selfIntro: null);
    expect(cleared.analysis, isNull);
    expect(cleared.selfIntro, isNull);
    expect(cleared.answers, _full().answers); // untouched
  });

  test('enforces the photo and trait limits', () {
    final photo = ProfilePhoto(id: 'p', localPath: '/p.jpg', addedAt: _t);
    expect(
      () => _minimal().copyWith(photos: List.filled(4, photo)),
      throwsArgumentError,
    );
    expect(
      () => IntakeAnalysis(
        aboutMe: '',
        traits: List.filled(5, const Trait(label: 'a', reason: 'b')),
        brief: '',
        language: AppLanguage.en,
        generatedAt: _t,
      ),
      throwsArgumentError,
    );
  });

  group('migrate', () {
    test('treats a missing schema as version 1', () {
      final json = _minimal().toJson()..remove('schema');
      expect(UserProfile.fromJson(json), _minimal());
    });

    test('rejects data saved by a newer app version', () {
      final json = _minimal().toJson()..['schema'] = 99;
      expect(() => UserProfile.fromJson(json), throwsFormatException);
    });

    test('rejects malformed data with a FormatException', () {
      final json = _minimal().toJson()..['gender'] = 'unknown';
      expect(() => UserProfile.fromJson(json), throwsFormatException);
      final noUid = _minimal().toJson()..remove('uid');
      expect(() => UserProfile.fromJson(noUid), throwsFormatException);
    });
  });
}
