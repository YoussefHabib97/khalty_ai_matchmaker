import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_failure.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/prefs.dart';

void main() {
  const phone = '+966501234567';

  Future<FakeAuthRepository> repo([
    Map<String, Object> stored = const {},
  ]) async => FakeAuthRepository(await mockPrefs(stored), delay: Duration.zero);

  test('starts signed out', () async {
    expect((await repo()).currentUser, isNull);
  });

  test('a wrong code is rejected', () async {
    final auth = await repo();
    final request = await auth.sendCode(phone);
    expect(
      () => auth.verifyCode(request, '000000'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.invalidCode,
        ),
      ),
    );
    expect(auth.currentUser, isNull);
  });

  test('the right code signs in and announces it', () async {
    final auth = await repo();
    final changes = <AuthUser?>[];
    auth.authStateChanges().listen(changes.add);

    final request = await auth.sendCode(phone);
    final user = await auth.verifyCode(request, FakeAuthRepository.code);

    expect(user.phoneE164, phone);
    expect(auth.currentUser, user);
    await Future<void>.delayed(Duration.zero);
    expect(changes, [user]);
  });

  test('the same phone always gets the same uid', () async {
    final auth = await repo();
    final first = await auth.verifyCode(await auth.sendCode(phone), '123456');
    await auth.signOut();
    final again = await auth.verifyCode(await auth.sendCode(phone), '123456');
    expect(again.uid, first.uid);
  });

  test('the session survives a restart; sign-out clears it', () async {
    final auth = await repo();
    final user = await auth.verifyCode(await auth.sendCode(phone), '123456');

    final prefs = SharedPrefs(await SharedPreferences.getInstance());
    expect(FakeAuthRepository(prefs).currentUser, user);

    await auth.signOut();
    expect(auth.currentUser, isNull);
    expect(FakeAuthRepository(prefs).currentUser, isNull);
  });

  test('an unreadable stored session counts as signed out', () async {
    final auth = await repo({FakeAuthRepository.sessionKey: 'not json'});
    expect(auth.currentUser, isNull);
  });
}
