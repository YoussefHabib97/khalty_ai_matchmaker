import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_completeness.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final engine = QuestionnaireEngine(loadRealConfig(), Gender.female);
  // Every question answered (optional ones too), a typed introduction and
  // Khalty's bio, no photo.
  final finished = profileAt(OnboardingStage.complete);
  final photo = ProfilePhoto(
    id: 'p1',
    localPath: '/p1.jpg',
    addedAt: sessionTime,
  );

  Completeness of(UserProfile p) => ProfileCompleteness.of(p, engine);

  test('the weights add up to 100', () {
    expect(ProfilePart.values.fold(0, (sum, p) => sum + p.weight), 100);
  });

  test('everything but a photo: 90%, suggest a photo', () {
    expect(
      of(finished),
      const Completeness(percent: 90, nextStep: ProfilePart.photo),
    );
  });

  test('with a photo: 100%, nothing to suggest', () {
    expect(
      of(finished.copyWith(photos: [photo])),
      const Completeness(percent: 100, nextStep: null),
    );
  });

  test('a skipped introduction (and so no bio) is suggested first', () {
    final skipped = finished.copyWith(
      selfIntro: SelfIntro.skipped(at: sessionTime),
      analysis: IntakeAnalysis(
        traits: const [],
        brief: 'Brief',
        language: AppLanguage.en,
        generatedAt: sessionTime,
      ),
    );
    expect(
      of(skipped),
      const Completeness(percent: 60, nextStep: ProfilePart.introduction),
    );
  });

  test('the user\'s own bio counts even without Khalty\'s', () {
    final ownBio = finished.copyWith(
      selfIntro: SelfIntro.skipped(at: sessionTime),
      aboutMe: 'I teach and love books.',
      analysis: null,
    );
    expect(of(ownBio).percent, 70);
  });

  test('a skipped optional question (height) counts as missing', () {
    final skippedOne = finished.copyWith(
      answers: finished.answers.set('height_cm', const SkippedAnswer()),
      photos: [photo],
    );
    expect(
      of(skippedOne),
      const Completeness(percent: 90, nextStep: ProfilePart.optionalDetails),
    );
  });

  test('a question without an answer (added later) comes first', () {
    final missing = finished.copyWith(
      answers: finished.answers.remove('city'),
      photos: [photo],
    );
    final result = of(missing);
    expect(result.nextStep, ProfilePart.questions);
    expect(result.percent, lessThan(100));
  });
}
