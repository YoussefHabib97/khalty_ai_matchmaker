import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/core/l10n/cubit/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/theme/cubit/theme_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });
  tearDown(() => getIt.reset());

  test('every registration resolves', () {
    expect(getIt<SharedPreferences>(), isNotNull);
    expect(getIt<SharedPrefs>(), isNotNull);
    expect(getIt<AppThemeCubit>(), isNotNull);
    expect(getIt<LocaleCubit>(), isNotNull);
  });

  test('services are singletons, cubits are new instances', () {
    expect(identical(getIt<SharedPrefs>(), getIt<SharedPrefs>()), isTrue);
    expect(identical(getIt<AppThemeCubit>(), getIt<AppThemeCubit>()), isFalse);
    expect(identical(getIt<LocaleCubit>(), getIt<LocaleCubit>()), isFalse);
  });
}
