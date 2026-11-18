import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/account_cubit.dart';

import '../../../../helpers/prefs.dart';
import '../../../../helpers/session.dart';

void main() {
  test(
    'shows the number; signing out also deletes the local profile',
    () async {
      final prefs = await mockPrefs(storedSessionAt(OnboardingStage.complete));
      final auth = FakeAuthRepository(prefs, delay: Duration.zero);
      final profiles = LocalProfileRepository(prefs);
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      final cubit = AccountCubit(auth: auth, profiles: profiles);
      addTearDown(cubit.close);

      expect(cubit.state.phoneE164, testUser.phoneE164);
      await cubit.signOut();
      expect(auth.currentUser, isNull);
      expect(profiles.current, isNull);
    },
  );
}
