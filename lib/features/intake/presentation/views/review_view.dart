import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/khalty_bubble.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/review_section_card.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_menu_button.dart';
import 'package:material_ui/material_ui.dart';

/// "What I understood": Khalty's message, the summary, the bio for the
/// profile card and anything to double-check, then **Edit** or
/// **That's me ✓**. Expects a [ReviewCubit] above it. Both actions change
/// the profile and the session moves on, so no navigation callback.
class ReviewView extends StatelessWidget {
  const ReviewView({super.key, required this.onChangeAnswers});

  /// Edit → "Change an answer" (open answer editing).
  final VoidCallback onChangeAnswers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, state) {
        final analysis = state.analysis;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(l10n.reviewTitle),
            actions: const [LanguageMenuButton()],
          ),
          body: SafeArea(
            top: false,
            child: analysis == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: _content(context, state)),
                      _actions(context, state),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, ReviewState state) {
    final l10n = context.l10n;
    final analysis = state.analysis!;
    final colors = Theme.of(context).colorScheme;
    // Khalty's texts stay in the language they were written in.
    final writtenIn = analysis.language == context.appLanguage
        ? null
        : switch (analysis.language) {
            AppLanguage.en => l10n.writtenInEnglish,
            AppLanguage.ar => l10n.writtenInArabic,
          };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KhaltyBubble(
          emphasised: false,
          text: analysis.reply ?? l10n.reviewFallbackReply(state.name ?? ''),
        ),
        if (writtenIn != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8, start: 52),
            child: Row(
              spacing: 4,
              children: [
                Icon(Icons.translate, size: 16, color: colors.onSurfaceVariant),
                Text(
                  writtenIn,
                  style: context.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ReviewSectionCard(
          title: l10n.reviewSummary,
          icon: Icons.person_outline,
          child: Text(analysis.brief),
        ),
        const SizedBox(height: 12),
        ReviewSectionCard(
          title: l10n.reviewAboutMe,
          icon: Icons.badge_outlined,
          child: Text(analysis.aboutMe ?? l10n.reviewNoAboutMe),
        ),
        if (analysis.mismatches.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReviewSectionCard(
            key: const Key('reviewPleaseCheck'),
            title: l10n.reviewPleaseCheck,
            icon: Icons.info_outline,
            attention: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                for (final item in analysis.mismatches) Text('• $item'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _actions(BuildContext context, ReviewState state) {
    final l10n = context.l10n;
    final cubit = context.read<ReviewCubit>();
    final enabled = !state.isSaving;
    return DefaultPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (state.saveFailed)
            Text(
              l10n.answerSaveFailed,
              style: context.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: MenuAnchor(
                  builder: (context, controller, _) => OutlinedButton(
                    key: const Key('reviewEdit'),
                    onPressed: enabled
                        ? () => controller.isOpen
                              ? controller.close()
                              : controller.open()
                        : null,
                    child: Text(l10n.reviewEdit),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      key: const Key('reviewRewrite'),
                      leadingIcon: const Icon(Icons.edit_note),
                      onPressed: cubit.rewriteIntroduction,
                      child: Text(l10n.reviewRewriteIntro),
                    ),
                    MenuItemButton(
                      key: const Key('reviewChangeAnswers'),
                      leadingIcon: const Icon(Icons.checklist),
                      onPressed: onChangeAnswers,
                      child: Text(l10n.reviewChangeAnswer),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FilledButton(
                  key: const Key('reviewConfirm'),
                  onPressed: enabled ? cubit.confirm : null,
                  child: Text(l10n.reviewConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
