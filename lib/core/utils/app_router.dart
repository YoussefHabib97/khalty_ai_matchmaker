import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/onboarding_view.dart';

abstract class AppRouter {
  static const String kOnboardingView = '/onboardingView';

  static var router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => OnboardingView())],
  );
}
