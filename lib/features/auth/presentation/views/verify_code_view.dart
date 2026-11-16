import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/utils/digits.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_state.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/resend_code_button.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/sign_up_error_text.dart';
import 'package:material_ui/material_ui.dart';

/// Enter the 6-digit SMS code. Expects the same [SignUpCubit] as sign-up.
class VerifyCodeView extends StatelessWidget {
  const VerifyCodeView({super.key, required this.onChangeNumber});

  /// Called to go back and edit the number.
  final VoidCallback onChangeNumber;

  static const codeLength = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SignUpCubit>();
    return PopScope(
      // System Back also returns to editing the number.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.editNumber();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.verifyCodeTitle)),
        body: BlocBuilder<SignUpCubit, SignUpState>(
          builder: (context, state) {
            final phone = state.otp?.phoneE164 ?? '';
            return SingleChildScrollView(
              child: DefaultPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    // Isolate the number so it stays left-to-right in Arabic.
                    Text(
                      l10n.codeSentTo('\u2066$phone\u2069'),
                      style: context.bodyLarge,
                    ),
                    TextField(
                      autofocus: true,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: codeLength,
                      enabled: !state.isBusy,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9٠-٩۰-۹]'),
                        ),
                      ],
                      style: context.headlineSmall.copyWith(letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: l10n.codeLabel,
                        border: const OutlineInputBorder(),
                        counterText: '',
                        errorText: state.error == null
                            ? null
                            : signUpErrorText(l10n, state.error!),
                      ),
                      // Submits by itself once all digits are in.
                      onChanged: (value) {
                        final code = normalizeDigits(value);
                        if (code.length == codeLength) cubit.verify(code);
                      },
                    ),
                    if (state.isBusy)
                      const Center(child: CircularProgressIndicator()),
                    if (state.debugCodeHint != null)
                      Text(
                        l10n.testCodeHint(state.debugCodeHint!),
                        textAlign: TextAlign.center,
                        style: context.bodySmall,
                      ),
                    ResendCodeButton(
                      remaining: cubit.resendRemaining,
                      onResend: cubit.resendCode,
                      enabled: !state.isBusy,
                    ),
                    TextButton(
                      onPressed: state.isBusy ? null : onChangeNumber,
                      child: Text(l10n.changeNumber),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
