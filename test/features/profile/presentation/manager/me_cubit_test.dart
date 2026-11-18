import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_cubit.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';

import '../../../../helpers/fake_photo_repository.dart';
import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final resolver = OnboardingStageResolver(loadRealConfig());
  late LocalProfileRepository profiles;

  Future<MeCubit> build(UserProfile profile) async {
    profiles = LocalProfileRepository(await mockPrefs());
    addTearDown(profiles.dispose);
    await profiles.save(profile);
    final cubit = MeCubit(
      profiles: profiles,
      photos: FakePhotoRepository(),
      engineFor: resolver.engineFor,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test(
    'shows the profile, where they live and how well Khalty knows them',
    () async {
      final cubit = await build(profileAt(OnboardingStage.complete));
      expect(cubit.state.profile?.name, 'Sara');
      expect(cubit.state.city, 'Something'); // the sample city
      expect(cubit.state.countryIso, 'SA');
      expect(cubit.state.completeness?.percent, 90);
    },
  );

  test('the silhouette follows the hijab or beard answer', () async {
    final woman = profileAt(OnboardingStage.complete);
    final cubit = await build(
      woman.copyWith(
        answers: woman.answers.set('hijab', const ChoiceAnswer('hijab')),
      ),
    );
    expect(cubit.state.silhouette, SilhouetteStyle.hijab);

    final man = profileAt(OnboardingStage.complete, gender: Gender.male);
    final manCubit = await build(
      man.copyWith(
        answers: man.answers
            .set('religious_commitment', const ChoiceAnswer('very_committed'))
            .set('beard', const ChoiceAnswer('trimmed_beard')),
      ),
    );
    expect(manCubit.state.silhouette, SilhouetteStyle.trimmedBeard);
  });

  test('a beard answer that no longer applies is ignored', () async {
    final man = profileAt(OnboardingStage.complete, gender: Gender.male);
    final cubit = await build(
      man.copyWith(
        answers: man.answers
            .set('beard', const ChoiceAnswer('full_beard'))
            // Beard is only asked to committed men.
            .set('religious_commitment', const ChoiceAnswer('not_practising')),
      ),
    );
    expect(cubit.state.silhouette, SilhouetteStyle.plain);
  });

  test('shows the main photo when there is one', () async {
    final cubit = await build(profileAt(OnboardingStage.complete));
    expect(cubit.state.mainPhotoPath, isNull);
    final photo = await FakePhotoRepository().add(PhotoSource.gallery);
    await profiles.save(profiles.current!.copyWith(photos: [photo!]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.mainPhotoPath, '/fake/photos/photo1.jpg');
  });

  test('follows later changes to the profile', () async {
    final cubit = await build(profileAt(OnboardingStage.complete));
    await profiles.save(profiles.current!.copyWith(aboutMe: 'My own words'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.profile?.effectiveAboutMe, 'My own words');
  });
}
