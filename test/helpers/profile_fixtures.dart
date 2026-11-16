import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answers.dart';

final fixtureTime = DateTime.utc(2026, 11, 16, 10);

/// A profile right after sign-up.
UserProfile minimalProfile() => UserProfile(
  uid: 'u1',
  gender: Gender.female,
  phoneE164: '+966501234567',
  consent: Consent(version: 1, acceptedAt: fixtureTime),
);

/// A profile with every part filled in.
UserProfile fullProfile() => minimalProfile().copyWith(
  answers: Answers({
    'name': const TextAnswer('Sara'),
    'age': const NumberAnswer(27),
  }),
  selfIntro: SelfIntro.typed('I love books.', at: fixtureTime),
  analysis: IntakeAnalysis(
    aboutMe: 'I am Sara.',
    traits: const [Trait(label: 'Kind', reason: 'Mentions family often')],
    brief: 'Sara is 27.',
    mismatches: const ['Mentions shisha, answered No to smoking'],
    language: AppLanguage.ar,
    generatedAt: fixtureTime,
  ),
  photos: [
    ProfilePhoto(id: 'p1', localPath: '/x/p1.jpg', addedAt: fixtureTime),
  ],
  sharePhotoWithMatch: true,
  progress: OnboardingProgress(
    intakeDoneAt: fixtureTime,
    selfIntroDoneAt: fixtureTime,
  ),
);
