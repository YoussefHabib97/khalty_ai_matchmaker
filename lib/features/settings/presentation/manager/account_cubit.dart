import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';

/// What the account part of Settings shows.
class AccountState {
  const AccountState({this.phoneE164, this.isSigningOut = false});

  /// The signed-in number.
  final String? phoneE164;
  final bool isSigningOut;
}

/// ViewModel for the account part of Settings. Signing out also deletes the
/// profile, because for now it is stored only on this phone; the session
/// then returns to Welcome.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit({required this._auth, required this._profiles})
    : super(AccountState(phoneE164: _auth.currentUser?.phoneE164));

  final AuthRepository _auth;
  final ProfileRepository _profiles;

  Future<void> signOut() async {
    if (state.isSigningOut) return;
    emit(AccountState(phoneE164: state.phoneE164, isSigningOut: true));
    await _auth.signOut();
    await _profiles.clear();
  }
}
