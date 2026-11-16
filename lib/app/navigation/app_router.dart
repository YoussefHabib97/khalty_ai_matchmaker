import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_actions.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_panel.dart';
import 'package:khalty_ai_matchmaker/app/navigation/app_routes.dart';
import 'package:khalty_ai_matchmaker/app/navigation/main_shell.dart';
import 'package:khalty_ai_matchmaker/app/navigation/redirect.dart';
import 'package:khalty_ai_matchmaker/app/navigation/stream_listenable.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/sign_up_view.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/views/verify_code_view.dart';
import 'package:khalty_ai_matchmaker/features/chats/presentation/views/chats_tab_view.dart';
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
/// whenever [session] changes. With [debug], every screen gets the debug
/// stage panel underneath (debug builds only).
GoRouter createAppRouter(SessionCubit session, {DebugStageActions? debug}) {
  Widget page(Widget child) =>
      debug == null ? child : DebugStagePanel(actions: debug, child: child);

  GoRoute route(
    String path,
    Widget screen, {
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    builder: (context, state) => page(screen),
    routes: routes,
  );

  return GoRouter(
    initialLocation: homeForStage(session.state.stage),
    refreshListenable: StreamListenable(session.stream),
    redirect: (context, state) =>
        resolveRedirect(session.state.stage, state.uri.path),
    routes: [
      route(AppRoutes.welcome, const WelcomeView()),
      route(
        AppRoutes.signUp,
        const SignUpView(),
        routes: [
          // Pushed over sign-up, so Back returns to edit the number.
          route('verify', const VerifyCodeView()),
        ],
      ),
      route(AppRoutes.intake, const IntakeView()),
      route(AppRoutes.selfIntro, const SelfIntroView()),
      route(AppRoutes.review, const ReviewView()),
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
