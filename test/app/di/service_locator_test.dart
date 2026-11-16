import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/repos/questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Needed to load the questionnaire asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });
  tearDown(() => getIt.reset());

  test('every registration resolves', () {
    expect(getIt<SharedPreferences>(), isNotNull);
    expect(getIt<SharedPrefs>(), isNotNull);
    expect(getIt<QuestionnaireConfig>().fields, isNotEmpty);
    expect(getIt<AppThemeCubit>(), isNotNull);
    expect(getIt<LocaleCubit>(), isNotNull);
  });

  test('repositories are registered by interface', () {
    expect(getIt<SettingsRepository>(), isA<LocalSettingsRepository>());
    expect(
      getIt<QuestionnaireRepository>(),
      isA<AssetQuestionnaireRepository>(),
    );
  });

  test('services are singletons, cubits are new instances', () {
    expect(identical(getIt<SharedPrefs>(), getIt<SharedPrefs>()), isTrue);
    expect(
      identical(getIt<SettingsRepository>(), getIt<SettingsRepository>()),
      isTrue,
    );
    expect(
      identical(getIt<QuestionnaireConfig>(), getIt<QuestionnaireConfig>()),
      isTrue,
    );
    expect(identical(getIt<AppThemeCubit>(), getIt<AppThemeCubit>()), isFalse);
    expect(identical(getIt<LocaleCubit>(), getIt<LocaleCubit>()), isFalse);
  });
}
