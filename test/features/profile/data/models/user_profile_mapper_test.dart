import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/user_profile_mapper.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';

import '../../../../helpers/profile_fixtures.dart';

/// Encodes to a JSON string and back, as storage does.
UserProfile roundTrip(UserProfile p) => UserProfileMapper.fromJson(
  Map<String, Object?>.from(
    jsonDecode(jsonEncode(UserProfileMapper.toJson(p))) as Map,
  ),
);

void main() {
  test('round-trips a minimal and a full profile', () {
    expect(roundTrip(minimalProfile()), minimalProfile());
    expect(roundTrip(fullProfile()), fullProfile());
  });

  test('round-trips skipped and voice self-introductions', () {
    final skipped = minimalProfile().copyWith(
      selfIntro: SelfIntro.skipped(at: fixtureTime),
    );
    final voice = minimalProfile().copyWith(
      selfIntro: SelfIntro.voice('transcript', at: fixtureTime),
    );
    expect(roundTrip(skipped), skipped);
    expect(roundTrip(voice), voice);
  });

  test("round-trips Khalty's message and a missing bio", () {
    final full = fullProfile();
    final withReply = full.copyWith(
      analysis: IntakeAnalysis(
        traits: const [],
        brief: 'Brief',
        language: AppLanguage.en,
        generatedAt: fixtureTime,
        reply: 'Thank you, Sara',
      ),
    );
    expect(roundTrip(withReply), withReply);
    expect(roundTrip(withReply).analysis!.aboutMe, isNull);
  });

  test('reads an analysis saved before the message existed', () {
    final json = UserProfileMapper.toJson(fullProfile());
    (json['analysis'] as Map).remove('reply');
    final profile = UserProfileMapper.fromJson(json);
    expect(profile.analysis!.reply, isNull);
    expect(profile.analysis!.aboutMe, 'I am Sara.');
  });

  test('stores enums by name and includes the schema version', () {
    final json = UserProfileMapper.toJson(fullProfile());
    expect(json['schema'], UserProfileMapper.schemaVersion);
    expect(json['gender'], 'female');
    expect((json['analysis'] as Map)['language'], 'ar');
  });

  group('migrate', () {
    Map<String, Object?> minimalJson() =>
        UserProfileMapper.toJson(minimalProfile());

    test('treats a missing schema as version 1', () {
      final json = minimalJson()..remove('schema');
      expect(UserProfileMapper.fromJson(json), minimalProfile());
    });

    test('rejects data saved by a newer app version', () {
      final json = minimalJson()..['schema'] = 99;
      expect(() => UserProfileMapper.fromJson(json), throwsFormatException);
    });

    test('rejects malformed data with a FormatException', () {
      final badGender = minimalJson()..['gender'] = 'unknown';
      expect(
        () => UserProfileMapper.fromJson(badGender),
        throwsFormatException,
      );
      final noUid = minimalJson()..remove('uid');
      expect(() => UserProfileMapper.fromJson(noUid), throwsFormatException);
    });
  });
}
