import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_state.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/answer_editor.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/invalid_answer_text.dart';
import 'package:material_ui/material_ui.dart';

/// Edits one answer in a bottom sheet with the same inputs as the
/// questionnaire. Returns true when an answer was accepted. [followUp]
/// shows that the question now applies because of another edit.
Future<bool> showEditAnswerSheet(
  BuildContext context, {
  required FieldDef field,
  bool followUp = false,
}) async {
  final cubit = context.read<EditProfileCubit>();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _EditAnswerSheet(field: field, followUp: followUp),
    ),
  );
  cubit.clearError();
  return saved ?? false;
}

class _EditAnswerSheet extends StatelessWidget {
  const _EditAnswerSheet({required this.field, required this.followUp});

  final FieldDef field;
  final bool followUp;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();
    final l10n = context.l10n;
    final language = context.appLanguage;
    final gender = cubit.gender;
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<EditProfileCubit, EditProfileState>(
      builder: (context, state) {
        final suggested = switch (cubit.suggestedCountry(field)) {
          final iso? => countryByIso(iso),
          null => null,
        };
        final vars = {
          'name': ?state.profile?.name,
          if (suggested != null) ...{
            'detected': suggested.name(language),
            'residence': suggested.name(language),
          },
        };
        // Country questions read "Which country…?" here.
        final question =
            (field.input.isCountry ? field.questionPick : null) ??
            field.question;

        void close() => Navigator.of(context).pop(true);

        return Padding(
          // Above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AnswerEditor(
            key: ValueKey(field.key),
            field: field,
            gender: gender,
            earlier: state.answers[field.key],
            // Editing a country: pick from the list (no "Are you living
            // in…?" confirmation); a second nationality shows its answer.
            suggestedCountry: field.input == InputType.countryOptional
                ? suggested
                : null,
            suggestedRange: cubit.suggestedRange(field),
            pickTitle: question.resolve(language, gender, vars: vars),
            errorText: switch (state.invalid) {
              final reason? => invalidAnswerText(
                l10n,
                language,
                gender,
                field,
                reason,
              ),
              null => null,
            },
            submitLabel: l10n.save,
            onSubmit: (value) async {
              if (await cubit.saveAnswer(field, value)) close();
            },
            onSubmitTyped: (raw) async {
              if (await cubit.saveTyped(field, raw)) close();
            },
            onSkip: () async {
              if (await cubit.saveAnswer(field, const SkippedAnswer())) {
                close();
              }
            },
            onDraftChanged: cubit.clearError,
            layout: (context, input, actions) => SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  if (followUp)
                    Row(
                      spacing: 8,
                      children: [
                        Icon(Icons.info_outline, color: colors.tertiary),
                        Expanded(
                          child: Text(
                            l10n.nowApplies,
                            style: context.bodyMedium.copyWith(
                              color: colors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Text(
                    question.resolve(language, gender, vars: vars),
                    style: context.titleLarge,
                  ),
                  input,
                  ?actions,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
