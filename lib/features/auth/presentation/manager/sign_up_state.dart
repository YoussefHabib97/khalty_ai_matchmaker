import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/phone_numbers.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/entities/otp_request.dart';

enum SignUpStatus { editing, sendingCode, codeSent, verifying, creatingProfile }

/// What went wrong, shown next to the related field.
enum SignUpError {
  genderMissing,
  phoneInvalid,
  consentMissing,
  invalidCode,
  codeExpired,
  tooManyAttempts,
  network,
}

/// Everything the sign-up and code screens show.
class SignUpState {
  const SignUpState({
    required this.country,
    this.gender,
    this.phoneDigits = '',
    this.consent = false,
    this.status = SignUpStatus.editing,
    this.error,
    this.otp,
    this.codeSentAt,
    this.debugCodeHint,
  });

  final Country country;
  final Gender? gender;

  /// The phone number as typed (national part).
  final String phoneDigits;
  final bool consent;
  final SignUpStatus status;
  final SignUpError? error;

  /// The current SMS code request, once a code has been sent.
  final OtpRequest? otp;
  final DateTime? codeSentAt;

  /// Debug builds only: the fake SMS code to show on screen.
  final String? debugCodeHint;

  bool get isBusy =>
      status == SignUpStatus.sendingCode ||
      status == SignUpStatus.verifying ||
      status == SignUpStatus.creatingProfile;

  /// The number in international format, or null if it isn't valid.
  String? get phoneE164 => toE164(country, phoneDigits);

  SignUpState copyWith({
    Country? country,
    Object? gender = _unset,
    String? phoneDigits,
    bool? consent,
    SignUpStatus? status,
    Object? error = _unset,
    Object? otp = _unset,
    Object? codeSentAt = _unset,
  }) => SignUpState(
    country: country ?? this.country,
    gender: _pick(gender, this.gender),
    phoneDigits: phoneDigits ?? this.phoneDigits,
    consent: consent ?? this.consent,
    status: status ?? this.status,
    error: _pick(error, this.error),
    otp: _pick(otp, this.otp),
    codeSentAt: _pick(codeSentAt, this.codeSentAt),
    debugCodeHint: debugCodeHint,
  );

  @override
  bool operator ==(Object other) =>
      other is SignUpState &&
      other.country == country &&
      other.gender == gender &&
      other.phoneDigits == phoneDigits &&
      other.consent == consent &&
      other.status == status &&
      other.error == error &&
      identical(other.otp, otp) &&
      other.codeSentAt == codeSentAt &&
      other.debugCodeHint == debugCodeHint;

  @override
  int get hashCode => Object.hash(
    country,
    gender,
    phoneDigits,
    consent,
    status,
    error,
    otp,
    codeSentAt,
    debugCodeHint,
  );
}

const _unset = Object();

T? _pick<T>(Object? value, T? current) =>
    identical(value, _unset) ? current : value as T?;
