import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_card.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/profile_preview_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/profile_preview_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/profile_card_view.dart';
import 'package:material_ui/material_ui.dart';

/// "See how Khalty presents you": the user's card as a suggested match sees
/// it, switchable between English and Arabic. Expects a
/// [ProfilePreviewCubit] above it.
class ProfilePreviewView extends StatelessWidget {
  const ProfilePreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mePreview)),
      body: BlocBuilder<ProfilePreviewCubit, ProfilePreviewState>(
        builder: (context, state) {
          final card = state.card;
          if (card == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final language = state.language ?? context.appLanguage;
          final photoNote = switch (card.photoNote) {
            CardPhotoNote.none => null,
            CardPhotoNote.visibleToSuggested => l10n.photosHintMan,
            CardPhotoNote.sharedAfterAccept => l10n.previewPhotoAfterAccept,
            CardPhotoNote.keptPrivate => l10n.previewPhotoPrivate,
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.previewIntro, style: context.bodyLarge),
              const SizedBox(height: 12),
              Row(
                spacing: 12,
                children: [
                  Text(l10n.previewShowIn, style: context.bodyMedium),
                  Expanded(
                    child: SegmentedButton<AppLanguage>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: AppLanguage.en,
                          label: Text(
                            l10n.languageEnglish,
                            key: const Key('previewIn-en'),
                          ),
                        ),
                        ButtonSegment(
                          value: AppLanguage.ar,
                          label: Text(
                            l10n.languageArabic,
                            key: const Key('previewIn-ar'),
                          ),
                        ),
                      ],
                      selected: {language},
                      onSelectionChanged: (selection) => context
                          .read<ProfilePreviewCubit>()
                          .showIn(selection.single),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProfileCardView(
                card: card,
                language: language,
                photoPath: state.photoPath,
              ),
              const SizedBox(height: 16),
              if (photoNote != null)
                _Note(icon: Icons.photo_outlined, text: photoNote),
              _Note(icon: Icons.lock_outline, text: l10n.previewPrivate),
            ],
          );
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(icon, size: 18, color: color),
          Expanded(
            child: Text(text, style: context.bodySmall.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
