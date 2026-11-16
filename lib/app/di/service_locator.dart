import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_actions.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_router.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/device_country.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
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
/// - Screen ViewModels (cubits): factories. `BlocProvider(create: ...)`
///   owns their lifecycle and closes them, so they must never be singletons.
/// - App-wide ViewModels that outlive every screen (the session) and the
///   router: singletons, provided with `BlocProvider.value`.
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
  getIt.registerLazySingleton<AuthRepository>(
    () => FakeAuthRepository(getIt()),
    dispose: (repo) => (repo as FakeAuthRepository).dispose(),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => LocalProfileRepository(getIt()),
    dispose: (repo) => (repo as LocalProfileRepository).dispose(),
  );

  // Data loaded once at startup. An invalid questionnaire stops the app here
  // with a ConfigException naming the problem (tests catch this first).
  getIt.registerSingleton<QuestionnaireConfig>(
    await getIt<QuestionnaireRepository>().load(),
  );

  // Domain services
  getIt.registerLazySingleton<OnboardingStageResolver>(
    () => OnboardingStageResolver(getIt()),
  );

  // App-wide ViewModel and navigation
  getIt.registerLazySingleton<SessionCubit>(
    () => SessionCubit(auth: getIt(), profiles: getIt(), resolver: getIt()),
    dispose: (session) => session.close(),
  );
  if (kDebugMode) {
    getIt.registerLazySingleton<DebugStageActions>(
      () => DebugStageActions(
        auth: getIt(),
        profiles: getIt(),
        resolver: getIt(),
      ),
    );
  }
  getIt.registerLazySingleton<GoRouter>(
    () => createAppRouter(
      getIt(),
      signUpCubit: () => getIt<SignUpCubit>(),
      debug: kDebugMode ? getIt<DebugStageActions>() : null,
    ),
    dispose: (router) => router.dispose(),
  );

  // Screen ViewModels (cubits)
  getIt.registerFactory<AppThemeCubit>(() => AppThemeCubit(getIt()));
  getIt.registerFactory<LocaleCubit>(() => LocaleCubit(getIt()));
  getIt.registerFactory<SignUpCubit>(
    () => SignUpCubit(
      auth: getIt(),
      profiles: getIt(),
      initialCountry: deviceCountry(),
      debugCodeHint: kDebugMode ? FakeAuthRepository.code : null,
    ),
  );
}
