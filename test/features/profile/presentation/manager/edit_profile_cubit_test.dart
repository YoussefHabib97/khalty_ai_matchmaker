import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/data/repos/fake_khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_cubit.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/engine_results.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

import '../../../../helpers/fake_photo_repository.dart';
import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();
  final resolver = OnboardingStageResolver(config);
  late LocalProfileRepository profiles;
  late FakePhotoRepository photos;
  late FakeKhaltyAiRepository ai;

  FieldDef field(String key) => config.field(key)!;
  UserProfile current() => profiles.current!;

  Future<EditProfileCubit> build({UserProfile? profile}) async {
    profiles = LocalProfileRepository(await mockPrefs());
    addTearDown(profiles.dispose);
    await profiles.save(profile ?? profileAt(OnboardingStage.complete));
    photos = FakePhotoRepository();
    ai = FakeKhaltyAiRepository(delay: Duration.zero);
    final cubit = EditProfileCubit(
      profiles: profiles,
      photos: photos,
      ai: ai,
      engineFor: resolver.engineFor,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('answers', () {
    test('lists the questions that apply, by chapter', () async {
      final cubit = await build();
      final sections = cubit.state.sections;
      expect(sections.map((s) => s.chapter.id), [1, 2, 3, 4, 5]);
      final keys = sections.expand((s) => s.rows).map((r) => r.field.key);
      expect(keys, contains('age'));
      // The sample answer is "never married": no children question.
      expect(keys, isNot(contains('children_now')));
      expect(keys, isNot(contains('beard'))); // women aren't asked
    });

    test('an edit is validated and saved straight away', () async {
      final cubit = await build();
      expect(await cubit.saveTyped(field('age'), '٣١'), isTrue);
      expect(current().answers['age'], const NumberAnswer(31));
      expect(cubit.state.answersChanged, isTrue);

      expect(await cubit.saveTyped(field('age'), '15'), isFalse);
      expect(cubit.state.invalid, InvalidReason.outOfRange);
      expect(current().answers['age'], const NumberAnswer(31));
      cubit.clearError();
      expect(cubit.state.invalid, isNull);
    });

    test('an edit that makes a question apply waits for its answer', () async {
      final cubit = await build();
      expect(
        await cubit.saveAnswer(
          field('marital_status'),
          const ChoiceAnswer('divorced'),
        ),
        isTrue,
      );
      expect(cubit.state.followUp?.key, 'children_now');
      // Not saved yet: the profile never has unanswered questions.
      expect(
        current().answers['marital_status'],
        const ChoiceAnswer('never_married'),
      );

      await cubit.saveAnswer(
        field('children_now'),
        const ChoiceAnswer('no_children'),
      );
      expect(cubit.state.followUp, isNull);
      expect(
        current().answers['marital_status'],
        const ChoiceAnswer('divorced'),
      );
      expect(
        current().answers['children_now'],
        const ChoiceAnswer('no_children'),
      );
      expect(
        cubit.state.sections.expand((s) => s.rows).map((r) => r.field.key),
        contains('children_now'),
      );
    });

    test('cancelling the follow-up drops the whole edit', () async {
      final cubit = await build();
      await cubit.saveAnswer(
        field('marital_status'),
        const ChoiceAnswer('divorced'),
      );
      cubit.cancelFollowUp();
      expect(cubit.state.pending, isNull);
      expect(
        current().answers['marital_status'],
        const ChoiceAnswer('never_married'),
      );
      expect(cubit.state.answersChanged, isFalse);
    });

    test('suggestions for country and range editors', () async {
      final cubit = await build();
      expect(cubit.suggestedCountry(field('country')), 'SA');
      expect(cubit.suggestedCountry(field('nationality')), 'SA');
      expect(cubit.suggestedRange(field('partner_age')), isNotNull);
    });
  });

  group('leaving', () {
    test('changed answers refresh the brief', () async {
      final cubit = await build();
      final before = current().analysis!;
      await cubit.saveTyped(field('age'), '31');
      await cubit.finish();
      final after = current().analysis!;
      expect(after.brief, contains('31'));
      expect(after.brief, isNot(before.brief));
      expect(after.aboutMe, before.aboutMe);
      expect(cubit.state.refreshingBrief, isFalse);
    });

    test('nothing changed: no refresh', () async {
      final cubit = await build();
      final before = current().analysis;
      await cubit.finish();
      expect(current().analysis, before);
    });

    test('an AI failure keeps the old brief', () async {
      final cubit = await build();
      final before = current().analysis!.brief;
      await cubit.saveTyped(field('age'), '31');
      ai.fail = true;
      await cubit.finish();
      expect(current().analysis!.brief, before);
    });
  });

  group('about me', () {
    test('contact details are removed and the user is told', () async {
      final cubit = await build();
      expect(
        await cubit.saveAboutMe('I teach. WhatsApp 0501234567 or @sara_k'),
        isTrue,
      );
      expect(current().aboutMe, isNot(contains('0501234567')));
      expect(current().aboutMe, isNot(contains('@sara_k')));
      expect(await cubit.saveAboutMe('  I love books.  '), isFalse);
      expect(current().effectiveAboutMe, 'I love books.');
    });

    test('an empty bio hides Khalty\'s suggestion', () async {
      final cubit = await build();
      await cubit.saveAboutMe('');
      expect(current().effectiveAboutMe, isEmpty);
    });
  });

  group('photos', () {
    test('add up to three; the first is the main photo', () async {
      final cubit = await build();
      for (var i = 0; i < 4; i++) {
        await cubit.addPhoto(PhotoSource.gallery);
      }
      expect(current().photos.map((p) => p.id), ['photo1', 'photo2', 'photo3']);
      expect(current().mainPhoto?.id, 'photo1');
    });

    test('make main, delete (with its file)', () async {
      final cubit = await build();
      await cubit.addPhoto(PhotoSource.gallery);
      await cubit.addPhoto(PhotoSource.camera);
      final second = current().photos[1];

      await cubit.makeMain(second);
      expect(current().mainPhoto, second);

      await cubit.removePhoto(second);
      expect(current().photos.map((p) => p.id), ['photo1']);
      expect(photos.deleted, [second]);
    });

    test('closing the picker adds nothing; a failure is reported', () async {
      final cubit = await build();
      photos.cancel = true;
      await cubit.addPhoto(PhotoSource.gallery);
      expect(current().photos, isEmpty);

      photos
        ..cancel = false
        ..fail = true;
      await cubit.addPhoto(PhotoSource.gallery);
      expect(cubit.state.photoFailed, isTrue);
      expect(cubit.state.busy, isFalse);
    });

    test('women can share their main photo after accepting', () async {
      final cubit = await build();
      await cubit.setSharePhoto(true);
      expect(current().sharePhotoWithMatch, isTrue);
    });

    test('photo paths come from the photo store', () async {
      final cubit = await build();
      await cubit.addPhoto(PhotoSource.gallery);
      expect(
        cubit.photoPath(current().photos.first),
        '/fake/photos/photo1.jpg',
      );
      expect(cubit.gender, Gender.female);
    });
  });
}
