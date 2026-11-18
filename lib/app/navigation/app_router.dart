import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_actions.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_panel.dart';
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
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the app's router. Created once by the service locator. Each
/// onboarding stage may only visit its own screens: the redirect re-runs
/// whenever [session] changes. Screens don't know routes: navigation is
/// passed to them as callbacks here. With [debug], every screen gets the
/// debug stage panel underneath (debug builds only).
GoRouter createAppRouter(
  SessionCubit session, {
  required SignUpCubit Function() signUpCubit,
  required IntakeCubit Function() intakeCubit,
  required SelfIntroCubit Function() selfIntroCubit,
  required ReviewCubit Function() reviewCubit,
  DebugStageActions? debug,
}) {
  Widget page(Widget child) =>
      debug == null ? child : DebugStagePanel(actions: debug, child: child);

  GoRoute route(
    String path,
    Widget Function(BuildContext context) screen, {
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    builder: (context, state) => page(screen(context)),
    routes: routes,
  );

  return GoRouter(
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
        (_) => BlocProvider(
          create: (_) => reviewCubit(),
          child: const ReviewView(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            page(MainShell(navigationShell: shell)),
        branches: [
          for (final (path, screen) in [
            (AppRoutes.khalty, const KhaltyTabView()),
            (AppRoutes.matches, const MatchesTabView()),
            (AppRoutes.chats, const ChatsTabView()),
            (AppRoutes.me, const MeView()),
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(path: path, builder: (context, state) => screen),
              ],
            ),
        ],
      ),
    ],
  );
}
