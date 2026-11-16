import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/prefs.dart';

void main() {
  test('first launch is a first run and clears the flag', () async {
    final prefs = await mockPrefs();
    expect(prefs.isAppFirstRun, isTrue);
    expect(prefs.getData(key: SharedPrefs.kIsAppFirstRunKey), isFalse);
  });

  test('later launches are not first runs and keep stored data', () async {
    final first = await mockPrefs();
    await first.setData(key: 'some.key', value: 'kept');

    // Simulate a restart over the same stored values.
    final restarted = SharedPrefs(await SharedPreferences.getInstance());
    expect(restarted.isAppFirstRun, isFalse);
    expect(restarted.getData(key: 'some.key'), 'kept');
  });

  test('a legacy stored `true` counts as a first run only once', () async {
    final legacy = await mockPrefs({SharedPrefs.kIsAppFirstRunKey: true});
    expect(legacy.isAppFirstRun, isTrue);

    final restarted = SharedPrefs(await SharedPreferences.getInstance());
    expect(restarted.isAppFirstRun, isFalse);
  });
}
