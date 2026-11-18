import 'package:khalty_ai_matchmaker/core/constants/countries.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/l10n/generated/app_localizations.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_card.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/presentation/widgets/answer_text.dart';
import 'package:material_ui/material_ui.dart';

/// The profile card as a suggested match sees it, written in [language]
/// (which may differ from the app language: the card is laid out in that
/// language's direction).
class ProfileCardView extends StatelessWidget {
  const ProfileCardView({
    super.key,
    required this.card,
    required this.language,
    this.photoPath,
  });

  final ProfileCard card;
  final AppLanguage language;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(Locale(language.code));
    final colors = Theme.of(context).colorScheme;
    final comma = language == AppLanguage.ar ? '، ' : ', ';
    final place = [
      ?card.city,
      if (card.countryIso case final iso?) ?countryByIso(iso)?.name(language),
    ].join(comma);
    final details = [
      if (card.age case final age?) l10n.ageYears(age),
      place,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Directionality(
      textDirection: language == AppLanguage.ar
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Card.outlined(
        key: Key('profileCard-${language.code}'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ProfileAvatar(
                  gender: card.gender,
                  silhouette: card.silhouette,
                  photoPath: photoPath,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card.name ?? '',
                style: context.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  style: context.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              if (card.aboutMe case final aboutMe?) ...[
                const SizedBox(height: 20),
                _Heading(l10n.meAboutMe),
                const SizedBox(height: 4),
                Text(aboutMe, style: context.bodyLarge),
              ],
              for (final section in card.sections) ...[
                const Divider(height: 32),
                _Heading(section.chapter.title.resolve(language, card.gender)),
                for (final item in section.items)
                  Padding(
                    key: Key('card-${item.field.key}'),
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.field.label!.resolve(language, card.gender),
                          style: context.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          answerText(
                                l10n,
                                language,
                                card.gender,
                                item.field,
                                item.value,
                              ) ??
                              '',
                          style: context.bodyLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.labelLarge.copyWith(
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
