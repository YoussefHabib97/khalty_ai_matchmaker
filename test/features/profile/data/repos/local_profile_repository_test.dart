import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/prefs.dart';
import '../../../../helpers/profile_fixtures.dart';

void main() {
  test('starts empty', () async {
    expect(LocalProfileRepository(await mockPrefs()).current, isNull);
  });

  test('save is announced and survives a restart', () async {
    final repo = LocalProfileRepository(await mockPrefs());
    final changes = <UserProfile?>[];
    repo.watch().listen(changes.add);

    await repo.save(fullProfile());
    expect(repo.current, fullProfile());

    final restarted = LocalProfileRepository(
      SharedPrefs(await SharedPreferences.getInstance()),
    );
    expect(restarted.current, fullProfile());
    await Future<void>.delayed(Duration.zero);
    expect(changes, [fullProfile()]);
  });

  test('clear removes it and is announced', () async {
    final repo = LocalProfileRepository(await mockPrefs());
    await repo.save(minimalProfile());
    final changes = <UserProfile?>[];
    repo.watch().listen(changes.add);

    await repo.clear();
    expect(repo.current, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(changes, [null]);
  });

  test('an unreadable profile is backed up, not lost', () async {
    final repo = LocalProfileRepository(
      await mockPrefs({LocalProfileRepository.key: '{"schema": 99}'}),
    );
    expect(repo.current, isNull);

    final raw = await SharedPreferences.getInstance();
    expect(raw.getString(LocalProfileRepository.corruptKey), '{"schema": 99}');
    expect(raw.getString(LocalProfileRepository.key), isNull);
  });
}
