/// A one-time code sent by SMS; pass it back to verify the code.
class OtpRequest {
  const OtpRequest({
    required this.phoneE164,
    required this.verificationId,
    required this.sentAt,
  });

  final String phoneE164;

  /// Identifies this code request with the auth provider.
  final String verificationId;
  final DateTime sentAt;
}
