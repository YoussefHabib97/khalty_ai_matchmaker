import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';

import '../../../../helpers/prefs.dart';

void main() {
  final sa = countryByIso('SA')!;
  late FakeAuthRepository auth;
  late LocalProfileRepository profiles;
  late DateTime now;

  Future<SignUpCubit> build({Map<String, Object> stored = const {}}) async {
    final prefs = await mockPrefs(stored);
    auth = FakeAuthRepository(prefs, delay: Duration.zero);
    profiles = LocalProfileRepository(prefs);
    now = DateTime.utc(2026, 11, 16, 10);
    final cubit = SignUpCubit(
      auth: auth,
      profiles: profiles,
      initialCountry: sa,
      now: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  void fillForm(SignUpCubit cubit) {
    cubit
      ..selectGender(Gender.female)
      ..phoneChanged('0501234567')
      ..consentChanged(true);
  }

  test('checks gender, then phone, then consent', () async {
    final cubit = await build();
    await cubit.submit();
    expect(cubit.state.error, SignUpError.genderMissing);

    cubit.selectGender(Gender.male);
    await cubit.submit();
    expect(cubit.state.error, SignUpError.phoneInvalid);

    cubit.phoneChanged('0501234567');
    await cubit.submit();
    expect(cubit.state.error, SignUpError.consentMissing);
  });

  test('editing a field clears the error', () async {
    final cubit = await build();
    await cubit.submit();
    cubit.selectGender(Gender.female);
    expect(cubit.state.error, isNull);
  });

  test('a valid form sends a code', () async {
    final cubit = await build();
    fillForm(cubit);
    await cubit.submit();

    expect(cubit.state.status, SignUpStatus.codeSent);
    expect(cubit.state.otp?.phoneE164, '+966501234567');
    expect(cubit.state.codeSentAt, now);
  });

  test('a wrong code is reported and nothing is saved', () async {
    final cubit = await build();
    fillForm(cubit);
    await cubit.submit();
    await cubit.verify('000000');

    expect(cubit.state.status, SignUpStatus.codeSent);
    expect(cubit.state.error, SignUpError.invalidCode);
    expect(profiles.current, isNull);
  });

  test('the right code creates the profile', () async {
    final cubit = await build();
    fillForm(cubit);
    await cubit.submit();
    await cubit.verify(FakeAuthRepository.code);

    final profile = profiles.current!;
    expect(profile.uid, auth.currentUser!.uid);
    expect(profile.gender, Gender.female);
    expect(profile.phoneE164, '+966501234567');
    expect(
      profile.consent,
      Consent(version: Consent.currentVersion, acceptedAt: now),
    );
  });

  test('already verified with this number: no code needed', () async {
    final cubit = await build(
      stored: {
        FakeAuthRepository.sessionKey:
            '{"uid":"fake-966501234567","phone":"+966501234567"}',
      },
    );
    // The verified number is pre-filled.
    expect(cubit.state.phoneDigits, '501234567');

    cubit
      ..selectGender(Gender.male)
      ..consentChanged(true);
    await cubit.submit();

    expect(cubit.state.otp, isNull);
    expect(profiles.current?.uid, 'fake-966501234567');
  });

  test('resend waits 60 seconds', () async {
    final cubit = await build();
    fillForm(cubit);
    await cubit.submit();
    final first = cubit.state.otp;

    now = now.add(const Duration(seconds: 30));
    expect(cubit.resendRemaining(), const Duration(seconds: 30));
    await cubit.resendCode();
    expect(cubit.state.otp, same(first));

    now = now.add(const Duration(seconds: 30));
    await cubit.resendCode();
    expect(cubit.state.otp, isNot(same(first)));
    expect(cubit.resendRemaining(), SignUpCubit.resendDelay);
  });

  test('going back and sending again soon reuses the code', () async {
    final cubit = await build();
    fillForm(cubit);
    await cubit.submit();
    final first = cubit.state.otp;

    cubit.editNumber();
    expect(cubit.state.status, SignUpStatus.editing);
    await cubit.submit();
    expect(cubit.state.status, SignUpStatus.codeSent);
    expect(cubit.state.otp, same(first));
  });
}
