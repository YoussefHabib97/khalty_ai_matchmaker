import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/di/app_dependencies.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_router.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';
import 'package:khalty_ai_matchmaker/core/theme/app_theme.dart';
import 'package:khalty_ai_matchmaker/core/theme/cubit/theme_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

class ApplicationRoot extends StatefulWidget {
  const ApplicationRoot({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ApplicationRoot> createState() => _ApplicationRootState();
}

class _ApplicationRootState extends State<ApplicationRoot> {
  // Created once so rebuilds (theme/locale changes) keep navigation state.
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.dependencies,
      child: ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        splitScreenMode: true,
        builder: (context, child) => PopScope(
          canPop: true,
          child: BlocProvider(
            create: (context) => AppThemeCubit(),
            child: BlocBuilder<AppThemeCubit, AppThemeState>(
              builder: (context, state) {
                return MaterialApp.router(
                  routerConfig: _router,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode:
                      state is DeviceDefaultThemeState ||
                          SharedPrefs.getData(key: kAppThemeKey) ==
                              kAppThemeDeviceDefault
                      ? ThemeMode.system
                      : state is LightThemeState ||
                            SharedPrefs.getData(key: kAppThemeKey) ==
                                kAppThemeLight
                      ? ThemeMode.light
                      : ThemeMode.dark,
                  debugShowCheckedModeBanner: false,
                  title: 'Khalty',
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
