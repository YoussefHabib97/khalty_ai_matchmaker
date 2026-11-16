import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/app/session/session_state.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';

/// App-wide ViewModel for the session. Recomputes the onboarding stage
/// whenever the signed-in user or the profile changes; the router listens to
/// it to send the user to the right screen.
///
/// Lives as long as the app: registered once in the service locator and
/// provided with `BlocProvider.value` (never closed by a screen).
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required AuthRepository auth,
    required ProfileRepository profiles,
    required OnboardingStageResolver resolver,
  }) : _auth = auth,
       _profiles = profiles,
       _resolver = resolver,
       super(_compute(auth, profiles, resolver)) {
    _subscriptions = [
      auth.authStateChanges().listen((_) => _refresh()),
      profiles.watch().listen((_) => _refresh()),
    ];
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final OnboardingStageResolver _resolver;
  late final List<StreamSubscription<Object?>> _subscriptions;

  void _refresh() {
    if (!isClosed) emit(_compute(_auth, _profiles, _resolver));
  }

  static SessionState _compute(
    AuthRepository auth,
    ProfileRepository profiles,
    OnboardingStageResolver resolver,
  ) {
    final user = auth.currentUser;
    final profile = profiles.current;
    return SessionState(
      stage: resolver.resolve(user, profile),
      user: user,
      profile: profile,
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
