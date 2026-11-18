import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_card.dart';

/// Everything the card preview shows.
class ProfilePreviewState {
  const ProfilePreviewState({this.card, this.photoPath, this.language});

  /// Null only when signed out meanwhile (the router is leaving).
  final ProfileCard? card;

  /// Where to show the card's photo from; null shows the silhouette.
  final String? photoPath;

  /// The language the card is shown in; null = the app language.
  final AppLanguage? language;

  ProfilePreviewState copyWith({AppLanguage? language}) => ProfilePreviewState(
    card: card,
    photoPath: photoPath,
    language: language ?? this.language,
  );
}
