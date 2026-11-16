import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/onboarding_view.dart';

abstract final class AppRoutes {
  static const String onboarding = '/';
}

/// Creates the app's router. Call once and keep the instance (see
/// [ApplicationRoot]); rebuilding it would reset navigation state.
GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
  ],
);
