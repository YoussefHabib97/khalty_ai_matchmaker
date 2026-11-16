/// Every route path in the app.
abstract final class AppRoutes {
  // Sign-up
  static const welcome = '/welcome';
  static const signUp = '/sign-up';
  static const verifyCode = '/sign-up/verify';

  // Onboarding questionnaire
  static const intake = '/intake';
  static const selfIntro = '/intake/intro';
  static const review = '/intake/review';

  // Main app (bottom navigation)
  static const homePrefix = '/home/';
  static const khalty = '/home/khalty';
  static const matches = '/home/matches';
  static const chats = '/home/chats';
  static const me = '/home/me';
}
