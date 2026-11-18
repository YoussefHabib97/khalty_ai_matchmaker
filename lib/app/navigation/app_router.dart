import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_routes.dart';
import 'package:khalty_ai_matchmaker/app/navigation/main_shell.dart';
import 'package:khalty_ai_matchmaker/app/navigation/redirect.dart';
import 'package:khalty_ai_matchmaker/app/navigation/stream_listenable.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/sign_up_view.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/verify_code_view.dart';
import 'package:khalty_ai_matchmaker/features/chats/presentation/views/chats_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/intake_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/review_view.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/self_intro_view.dart';
import 'package:khalty_ai_matchmaker/features/khalty_chat/presentation/views/khalty_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/matches/presentation/views/matches_tab_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/welcome_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/profile_preview_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/edit_profile_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/profile_preview_view.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/account_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/views/settings_view.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the app's router. Created once by the service locator. Each
/// onboarding stage may only visit its own screens: the redirect re-runs
/// whenever [session] changes. Screens don't know routes: navigation is
/// passed to them as callbacks here.
GoRouter createAppRouter(
  SessionCubit session, {
  required SignUpCubit Function() signUpCubit,
  required IntakeCubit Function() intakeCubit,
  required SelfIntroCubit Function() selfIntroCubit,
  required ReviewCubit Function() reviewCubit,
  required MeCubit Function() meCubit,
  required EditProfileCubit Function() editProfileCubit,
  required ProfilePreviewCubit Function() previewCubit,
  required AccountCubit Function() accountCubit,
}) {
  // Screens pushed over the bottom navigation use the root navigator.
  final rootNavigator = GlobalKey<NavigatorState>();

  Widget editProfile(BuildContext context) => BlocProvider(
    create: (_) => editProfileCubit(),
    child: EditProfileView(onDone: () => context.pop()),
  );

  GoRoute route(
    String path,
    Widget Function(BuildContext context) screen, {
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    builder: (context, state) => screen(context),
    routes: routes,
  );

  return GoRouter(
    navigatorKey: rootNavigator,
    initialLocation: homeForStage(session.state.stage),
    refreshListenable: StreamListenable(session.stream),
    redirect: (context, state) =>
        resolveRedirect(session.state.stage, state.uri.path),
    routes: [
      route(
        AppRoutes.welcome,
        (context) =>
            WelcomeView(onGetStarted: () => context.push(AppRoutes.signUp)),
      ),
      // One SignUpCubit shared by the sign-up and code screens; closed when
      // the user leaves sign-up.
      ShellRoute(
        builder: (context, state, child) =>
            BlocProvider(create: (_) => signUpCubit(), child: child),
        routes: [
          route(
            AppRoutes.signUp,
            (context) =>
                SignUpView(onCodeSent: () => context.go(AppRoutes.verifyCode)),
            routes: [
              // Stacked over sign-up, so Back returns to edit the number.
              route(
                'verify',
                (context) =>
                    VerifyCodeView(onChangeNumber: () => context.pop()),
              ),
            ],
          ),
        ],
      ),
      route(
        AppRoutes.intake,
        (_) => BlocProvider(
          create: (_) => intakeCubit(),
          child: const IntakeView(),
        ),
      ),
      route(
        AppRoutes.selfIntro,
        (_) => BlocProvider(
          create: (_) => selfIntroCubit(),
          child: const SelfIntroView(),
        ),
      ),
      route(
        AppRoutes.review,
        (context) => BlocProvider(
          create: (_) => reviewCubit(),
          child: ReviewView(
            onChangeAnswers: () => context.push(AppRoutes.reviewEdit),
          ),
        ),
        routes: [route('edit', editProfile)],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          for (final (path, screen) in [
            (AppRoutes.khalty, const KhaltyTabView()),
            (AppRoutes.matches, const MatchesTabView()),
            (AppRoutes.chats, const ChatsTabView()),
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(path: path, builder: (context, state) => screen),
              ],
            ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.me,
                builder: (context, state) => BlocProvider(
                  create: (_) => meCubit(),
                  child: MeView(
                    onOpenSettings: () => context.push(AppRoutes.settings),
                    onEditProfile: () => context.push(AppRoutes.editProfile),
                    onPreview: () => context.push(AppRoutes.preview),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => editProfile(context),
                  ),
                  GoRoute(
                    path: 'preview',
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => BlocProvider(
                      create: (_) => previewCubit(),
                      child: const ProfilePreviewView(),
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => BlocProvider(
                      create: (_) => accountCubit(),
                      child: const SettingsView(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
