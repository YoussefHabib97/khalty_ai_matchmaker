import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/theme/app_theme.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:material_ui/material_ui.dart';

/// The app widget. [router] and [session] are app-lifetime singletons from
/// the service locator (passed in by `main`, so this widget stays testable).
class ApplicationRoot extends StatelessWidget {
  const ApplicationRoot({
    super.key,
    required this.router,
    required this.session,
  });

  final GoRouter router;
  final SessionCubit session;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      splitScreenMode: true,
      builder: (context, child) => PopScope(
        canPop: true,
        child: MultiBlocProvider(
          providers: [
            // App-wide: provided by value so no screen ever closes it.
            BlocProvider.value(value: session),
            BlocProvider(create: (context) => getIt<AppThemeCubit>()),
            BlocProvider(create: (context) => getIt<LocaleCubit>()),
          ],
          child: Builder(
            builder: (context) {
              final locale = context.watch<LocaleCubit>().state;
              final themeMode = context.watch<AppThemeCubit>().themeMode;
              return MaterialApp.router(
                routerConfig: router,
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
