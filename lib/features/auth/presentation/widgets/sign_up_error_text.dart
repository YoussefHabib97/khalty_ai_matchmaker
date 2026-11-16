import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_state.dart';

/// The message shown for each sign-up error.
String signUpErrorText(AppLocalizations l10n, SignUpError error) =>
    switch (error) {
      SignUpError.genderMissing => l10n.errorPickGender,
      SignUpError.phoneInvalid => l10n.errorPhoneInvalid,
      SignUpError.consentMissing => l10n.errorAgreeFirst,
      SignUpError.invalidCode => l10n.errorCodeWrong,
      SignUpError.codeExpired => l10n.errorCodeExpired,
      SignUpError.tooManyAttempts => l10n.errorTooManyAttempts,
      SignUpError.network => l10n.errorSendFailed,
    };
