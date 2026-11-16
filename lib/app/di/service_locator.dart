import 'package:get_it/get_it.dart';
import 'package:khalty_ai_matchmaker/core/l10n/cubit/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/theme/cubit/theme_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// Registers every dependency once, at startup (and in tests after
/// `SharedPreferences.setMockInitialValues`; call `getIt.reset()` in tearDown).
///
/// - Services and repositories: singletons. This is the only place that
///   chooses implementations (local/fake now, Firebase later).
/// - Cubits: factories. `BlocProvider(create: (_) => getIt<X>())` owns their
///   lifecycle and closes them, so they must never be singletons.
Future<void> setupServiceLocator() async {
  // Services
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  // Eager, so the first-run check runs at startup.
  getIt.registerSingleton<SharedPrefs>(SharedPrefs(getIt()));

  // Cubits
  getIt.registerFactory<AppThemeCubit>(() => AppThemeCubit(getIt()));
  getIt.registerFactory<LocaleCubit>(() => LocaleCubit(getIt()));
}
