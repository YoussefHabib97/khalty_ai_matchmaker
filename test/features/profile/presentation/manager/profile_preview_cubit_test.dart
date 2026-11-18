import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/profile_preview_cubit.dart';

import '../../../../helpers/fake_photo_repository.dart';
import '../../../../helpers/prefs.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final resolver = OnboardingStageResolver(loadRealConfig());
  late LocalProfileRepository profiles;

  Future<ProfilePreviewCubit> build(UserProfile profile) async {
    profiles = LocalProfileRepository(await mockPrefs());
    addTearDown(profiles.dispose);
    await profiles.save(profile);
    final cubit = ProfilePreviewCubit(
      profiles: profiles,
      photos: FakePhotoRepository(),
      engineFor: resolver.engineFor,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('shows the card in the app language until switched', () async {
    final cubit = await build(profileAt(OnboardingStage.complete));
    expect(cubit.state.card?.name, 'Sara');
    expect(cubit.state.language, isNull);

    cubit.showIn(AppLanguage.ar);
    expect(cubit.state.language, AppLanguage.ar);
    expect(cubit.state.card, isNotNull);
  });

  test('follows profile edits, keeping the chosen language', () async {
    final cubit = await build(profileAt(OnboardingStage.complete));
    cubit.showIn(AppLanguage.ar);
    await profiles.save(profiles.current!.copyWith(aboutMe: 'I love books.'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.card?.aboutMe, 'I love books.');
    expect(cubit.state.language, AppLanguage.ar);
  });

  test("a man's photo is shown from the photo store", () async {
    final photo = ProfilePhoto(
      id: 'p1',
      localPath: 'photos/p1.jpg',
      addedAt: DateTime.utc(2026, 11, 18),
    );
    final cubit = await build(
      profileAt(
        OnboardingStage.complete,
        gender: Gender.male,
      ).copyWith(photos: [photo]),
    );
    expect(cubit.state.photoPath, '/fake/photos/p1.jpg');
  });
}
