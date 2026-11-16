import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_router.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/theme/app_theme.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

/// Requires `setupServiceLocator()` to have completed.
class ApplicationRoot extends StatefulWidget {
  const ApplicationRoot({super.key});

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
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      splitScreenMode: true,
      builder: (context, child) => PopScope(
        canPop: true,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => getIt<AppThemeCubit>()),
            BlocProvider(create: (context) => getIt<LocaleCubit>()),
          ],
          child: Builder(
            builder: (context) {
              final locale = context.watch<LocaleCubit>().state;
              final themeMode = context.watch<AppThemeCubit>().themeMode;
              return MaterialApp.router(
                routerConfig: _router,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                // material_ui's delegates, not the generated list (which
                // uses the deprecated flutter_localizations Material ones).
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                onGenerateTitle: (context) => context.l10n.appTitle,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        ),
      ),
    );
  }
}
