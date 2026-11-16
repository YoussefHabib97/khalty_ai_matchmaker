import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/country_picker_sheet.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_state.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/consent_checkbox.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/gender_selector.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/phone_number_field.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/widgets/sign_up_error_text.dart';
import 'package:material_ui/material_ui.dart';

/// Gender, phone number and consent. Expects a [SignUpCubit] above it.
class SignUpView extends StatelessWidget {
  const SignUpView({super.key, required this.onCodeSent});

  /// Called when a code has been sent (open the code screen).
  final VoidCallback onCodeSent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SignUpCubit>();
    return BlocListener<SignUpCubit, SignUpState>(
      listenWhen: (before, now) =>
          before.status != SignUpStatus.codeSent &&
          now.status == SignUpStatus.codeSent,
      listener: (context, state) => onCodeSent(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signUpTitle)),
        body: BlocBuilder<SignUpCubit, SignUpState>(
          builder: (context, state) {
            String? errorIf(SignUpError e) =>
                state.error == e ? signUpErrorText(l10n, e) : null;
            final generalError = state.error == SignUpError.network
                ? signUpErrorText(l10n, SignUpError.network)
                : null;
            return SingleChildScrollView(
              child: DefaultPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    GenderSelector(
                      selected: state.gender,
                      onSelected: cubit.selectGender,
                      errorText: errorIf(SignUpError.genderMissing),
                    ),
                    PhoneNumberField(
                      country: state.country,
                      initialValue: state.phoneDigits,
                      onChanged: cubit.phoneChanged,
                      errorText: errorIf(SignUpError.phoneInvalid),
                      onCountryTap: () async {
                        final country = await showCountryPicker(context);
                        if (country != null) cubit.selectCountry(country);
                      },
                    ),
                    ConsentCheckbox(
                      value: state.consent,
                      onChanged: cubit.consentChanged,
                      errorText: errorIf(SignUpError.consentMissing),
                    ),
                    if (generalError != null)
                      Text(
                        generalError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    FilledButton(
                      onPressed: state.isBusy ? null : cubit.submit,
                      child: state.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.sendCode),
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
