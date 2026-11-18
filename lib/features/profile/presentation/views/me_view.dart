import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_cubit.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_state.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/knows_you_card.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:material_ui/material_ui.dart';

/// Me tab: the user's own profile at a glance and the way to Settings.
/// Expects a [MeCubit] above it.
class MeView extends StatelessWidget {
  const MeView({
    super.key,
    required this.onOpenSettings,
    required this.onEditProfile,
  });

  /// Called by the settings button (open Settings).
  final VoidCallback onOpenSettings;

  /// Called by "Edit my profile" and the "knows you" card.
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMe),
        actions: [
          IconButton(
            key: const Key('openSettings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: BlocBuilder<MeCubit, MeState>(
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final language = context.appLanguage;
          final country = switch (state.countryIso) {
            final iso? => countryByIso(iso),
            null => null,
          };
          final details = [
            if (profile.age case final age?) l10n.ageYears(age),
            [
              ?state.city,
              ?country?.name(language),
            ].join(language == AppLanguage.ar ? '، ' : ', '),
          ].where((s) => s.isNotEmpty).join(' · ');
          final aboutMe = profile.effectiveAboutMe;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ProfileAvatar(
                  gender: profile.gender,
                  silhouette: state.silhouette,
                  photoPath: state.mainPhotoPath,
                  size: 112,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.name ?? '',
                style: context.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  style: context.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              if (state.completeness case final completeness?)
                KnowsYouCard(completeness: completeness, onTap: onEditProfile),
              const SizedBox(height: 12),
              Card.outlined(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(l10n.meAboutMe, style: context.labelLarge),
                      Text(
                        aboutMe == null || aboutMe.trim().isEmpty
                            ? l10n.meNoAboutMe
                            : aboutMe,
                        style: context.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Built in steps 12 and 13.
              ListTile(
                key: const Key('editProfile'),
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.meEditProfile),
                trailing: const Icon(Icons.chevron_right),
                onTap: onEditProfile,
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(l10n.mePreview),
                subtitle: Text(l10n.comingSoon),
                enabled: false,
              ),
            ],
          );
        },
      ),
    );
  }
}
