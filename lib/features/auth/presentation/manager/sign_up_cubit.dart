import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/phone_numbers.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_failure.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/auth_user.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';

/// ViewModel shared by the sign-up and code screens. When the profile is
/// saved, the session moves to the questionnaire and the router follows;
/// this cubit never navigates itself.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({
    required AuthRepository auth,
    required this._profiles,
    required Country initialCountry,
    this._now = DateTime.now,
    String? debugCodeHint,
  }) : _auth = auth,
       super(_initial(auth.currentUser, initialCountry, debugCodeHint));

  /// How long before another code can be requested.
  static const resendDelay = Duration(seconds: 60);

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final DateTime Function() _now;

  /// Signed in without a profile (e.g. the app closed after the code):
  /// pre-fill the verified number.
  static SignUpState _initial(AuthUser? user, Country fallback, String? hint) {
    if (user == null) {
      return SignUpState(country: fallback, debugCodeHint: hint);
    }
    final country = nationalNumber(fallback, user.phoneE164) != null
        ? fallback
        : _countryOf(user.phoneE164) ?? fallback;
    return SignUpState(
      country: country,
      phoneDigits: nationalNumber(country, user.phoneE164) ?? '',
      debugCodeHint: hint,
    );
  }

  /// The country whose dialling code is the longest prefix of [e164].
  static Country? _countryOf(String e164) {
    Country? best;
    for (final c in kCountries) {
      if (e164.startsWith('+${c.dialCode}') &&
          (best == null || c.dialCode.length > best.dialCode.length)) {
        best = c;
      }
    }
    return best;
  }

  // --- form ----------------------------------------------------------------

  void selectGender(Gender gender) =>
      _emit(state.copyWith(gender: gender, error: null));

  void selectCountry(Country country) =>
      _emit(state.copyWith(country: country, error: null));

  void phoneChanged(String digits) =>
      _emit(state.copyWith(phoneDigits: digits, error: null));

  void consentChanged(bool consent) =>
      _emit(state.copyWith(consent: consent, error: null));

  /// Checks the form, then sends a code (or skips it if this number is
  /// already verified).
  Future<void> submit() async {
    if (state.isBusy) return;
    final error = switch (state) {
      SignUpState(gender: null) => SignUpError.genderMissing,
      SignUpState(phoneE164: null) => SignUpError.phoneInvalid,
      SignUpState(consent: false) => SignUpError.consentMissing,
      _ => null,
    };
    if (error != null) return _emit(state.copyWith(error: error));

    final phone = state.phoneE164!;
    final user = _auth.currentUser;
    if (user != null && user.phoneE164 == phone) return _createProfile(user);

    // A code for this number was sent recently: reuse it, don't send another.
    if (state.otp?.phoneE164 == phone && resendRemaining() > Duration.zero) {
      return _emit(state.copyWith(status: SignUpStatus.codeSent, error: null));
    }
    await _sendCode(phone, onError: SignUpStatus.editing);
  }

  // --- code ----------------------------------------------------------------

  /// Time left before [resendCode] is allowed.
  Duration resendRemaining() {
    final sentAt = state.codeSentAt;
    if (sentAt == null) return Duration.zero;
    final left = sentAt.add(resendDelay).difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> resendCode() async {
    final otp = state.otp;
    if (otp == null || state.isBusy || resendRemaining() > Duration.zero) {
      return;
    }
    await _sendCode(otp.phoneE164, onError: SignUpStatus.codeSent);
  }

  /// Signs in with [code], then creates the profile.
  Future<void> verify(String code) async {
    final otp = state.otp;
    if (otp == null || state.isBusy) return;
    _emit(state.copyWith(status: SignUpStatus.verifying, error: null));
    try {
      await _createProfile(await _auth.verifyCode(otp, code));
    } on AuthException catch (e) {
      _emit(state.copyWith(status: SignUpStatus.codeSent, error: _map(e)));
    } on Object {
      _emit(
        state.copyWith(
          status: SignUpStatus.codeSent,
          error: SignUpError.network,
        ),
      );
    }
  }

  /// Back to the form to fix the number (the sent code is kept).
  void editNumber() =>
      _emit(state.copyWith(status: SignUpStatus.editing, error: null));

  // --- internals -------------------------------------------------------------

  Future<void> _sendCode(String phone, {required SignUpStatus onError}) async {
    _emit(state.copyWith(status: SignUpStatus.sendingCode, error: null));
    try {
      final otp = await _auth.sendCode(phone);
      _emit(
        state.copyWith(
          status: SignUpStatus.codeSent,
          otp: otp,
          codeSentAt: _now(),
        ),
      );
    } on AuthException catch (e) {
      _emit(state.copyWith(status: onError, error: _map(e)));
    } on Object {
      _emit(state.copyWith(status: onError, error: SignUpError.network));
    }
  }

  Future<void> _createProfile(AuthUser user) async {
    _emit(state.copyWith(status: SignUpStatus.creatingProfile, error: null));
    await _profiles.save(
      UserProfile(
        uid: user.uid,
        gender: state.gender!,
        phoneE164: user.phoneE164,
        consent: Consent(version: Consent.currentVersion, acceptedAt: _now()),
      ),
    );
  }

  static SignUpError _map(AuthException e) => switch (e.failure) {
    AuthFailure.invalidCode => SignUpError.invalidCode,
    AuthFailure.codeExpired => SignUpError.codeExpired,
    AuthFailure.tooManyAttempts => SignUpError.tooManyAttempts,
    AuthFailure.network => SignUpError.network,
  };

  /// Saving the profile navigates away and closes this cubit; ignore late
  /// updates instead of failing.
  void _emit(SignUpState next) {
    if (!isClosed) emit(next);
  }
}
