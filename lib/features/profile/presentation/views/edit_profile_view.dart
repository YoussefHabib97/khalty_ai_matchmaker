import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/edit_profile_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/about_me_sheet.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/edit_answer_sheet.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/photo_slots.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/answer_text.dart';
import 'package:material_ui/material_ui.dart';

/// Editing the profile: photos, About me, Khalty's private impressions
/// (read-only) and every answer by chapter. Each answer opens the same
/// inputs as the questionnaire in a sheet. Expects an [EditProfileCubit]
/// above it. Leaving refreshes Khalty's brief if answers changed, then
/// calls [onDone].
class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key, required this.onDone});

  /// Called to leave (go back).
  final VoidCallback onDone;

  Future<void> _leave(BuildContext context) async {
    await context.read<EditProfileCubit>().finish();
    onDone();
  }

  /// Edits [field], then any questions that now apply because of it.
  Future<void> _editAnswer(BuildContext context, FieldDef field) async {
    final cubit = context.read<EditProfileCubit>();
    var current = field;
    var followUp = false;
    while (context.mounted) {
      final saved = await showEditAnswerSheet(
        context,
        field: current,
        followUp: followUp,
      );
      if (!saved) {
        if (followUp) cubit.cancelFollowUp();
        return;
      }
      final next = cubit.state.followUp;
      if (next == null) return;
      current = next;
      followUp = true;
    }
  }

  Future<void> _editAboutMe(BuildContext context, String current) async {
    final cubit = context.read<EditProfileCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final cleaned = context.l10n.aboutMeCleaned;
    final text = await showAboutMeSheet(context, text: current);
    if (text == null) return;
    if (await cubit.saveAboutMe(text)) {
      messenger.showSnackBar(SnackBar(content: Text(cleaned)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listenWhen: (before, now) => !before.photoFailed && now.photoFailed,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.photoFailed))),
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !state.refreshingBrief) _leave(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: state.refreshingBrief ? null : () => _leave(context),
            ),
            title: Text(l10n.meEditProfile),
            bottom: state.refreshingBrief
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Column(
                      children: [
                        Text(l10n.updatingSummary, style: context.bodySmall),
                        const SizedBox(height: 4),
                        const LinearProgressIndicator(),
                      ],
                    ),
                  )
                : null,
          ),
          body: state.profile == null
              ? const Center(child: CircularProgressIndicator())
              : _content(context, state),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, EditProfileState state) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final cubit = context.read<EditProfileCubit>();
    final profile = state.profile!;
    final colors = Theme.of(context).colorScheme;
    final aboutMe = profile.effectiveAboutMe ?? '';
    final traits = profile.analysis?.traits ?? const [];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Header(l10n.editPhotos),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PhotoSlots(
            photos: profile.photos,
            pathOf: cubit.photoPath,
            enabled: !state.busy,
            onAdd: cubit.addPhoto,
            onMakeMain: cubit.makeMain,
            onDelete: cubit.removePhoto,
          ),
        ),
        if (profile.gender == Gender.female)
          SwitchListTile(
            key: const Key('sharePhoto'),
            title: Text(l10n.sharePhoto),
            subtitle: Text(l10n.sharePhotoHint),
            value: profile.sharePhotoWithMatch,
            onChanged: cubit.setSharePhoto,
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(l10n.photosHintMan, style: context.bodySmall),
          ),
        const Divider(height: 32),
        _Header(l10n.meAboutMe),
        ListTile(
          key: const Key('editAboutMe'),
          title: Text(
            aboutMe.trim().isEmpty ? l10n.meNoAboutMe : aboutMe,
            style: context.bodyLarge,
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editAboutMe(context, aboutMe),
        ),
        if (traits.isNotEmpty) ...[
          const Divider(height: 32),
          _Header(l10n.traitsTitle),
          for (final trait in traits)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.auto_awesome_outlined,
                color: colors.tertiary,
              ),
              title: Text(trait.label),
              subtitle: Text(trait.reason),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: Text(l10n.traitsHint, style: context.bodySmall),
          ),
        ],
        for (final section in state.sections) ...[
          const Divider(height: 32),
          _Header(section.chapter.title.resolve(language, cubit.gender)),
          for (final row in section.rows)
            ListTile(
              key: Key('edit-${row.field.key}'),
              title: Text(
                row.field.question.resolve(
                  language,
                  cubit.gender,
                  vars: {'name': ?profile.name},
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.bodyMedium,
              ),
              subtitle: Text(
                switch (row.value) {
                      final value? => answerText(
                        l10n,
                        language,
                        cubit.gender,
                        row.source,
                        value,
                      ),
                      null => null,
                    } ??
                    '—',
                style: context.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              trailing: row.field.visibility == FieldVisibility.khalty
                  ? Tooltip(
                      message: l10n.answerPrivate,
                      child: Icon(Icons.lock_outline, color: colors.outline),
                    )
                  : null,
              onTap: () => _editAnswer(context, row.field),
            ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
    child: Text(
      title,
      style: context.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
