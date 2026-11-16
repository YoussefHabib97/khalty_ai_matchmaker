import 'package:get_it/get_it.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/repos/questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// The composition root: the only place that picks implementations
/// (local/fake now, Firebase later) and wires them together. Called once at
/// startup (and in tests after `SharedPreferences.setMockInitialValues`;
/// call `getIt.reset()` in tearDown).
///
/// - Data sources and repositories: singletons, registered by their
///   **interface** type so everything above the data layer depends on
///   abstractions.
/// - Cubits (ViewModels): factories. `BlocProvider(create: (_) => getIt<X>())`
///   owns their lifecycle and closes them, so they must never be singletons.
Future<void> setupServiceLocator() async {
  // Data sources
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  // Eager, so the first-run check runs at startup.
  getIt.registerSingleton<SharedPrefs>(SharedPrefs(getIt()));

  // Repositories (interface -> implementation)
  getIt.registerLazySingleton<SettingsRepository>(
    () => LocalSettingsRepository(getIt()),
  );
  getIt.registerLazySingleton<QuestionnaireRepository>(
    AssetQuestionnaireRepository.new,
  );

  // Data loaded once at startup. An invalid questionnaire stops the app here
  // with a ConfigException naming the problem (tests catch this first).
  getIt.registerSingleton<QuestionnaireConfig>(
    await getIt<QuestionnaireRepository>().load(),
  );

  // Cubits (ViewModels)
  getIt.registerFactory<AppThemeCubit>(() => AppThemeCubit(getIt()));
  getIt.registerFactory<LocaleCubit>(() => LocaleCubit(getIt()));
}
