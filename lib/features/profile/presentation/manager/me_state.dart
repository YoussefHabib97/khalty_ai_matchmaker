import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/services/profile_completeness.dart';

/// Everything the Me tab shows.
class MeState {
  const MeState({
    this.profile,
    this.completeness,
    this.silhouette = SilhouetteStyle.plain,
    this.city,
    this.countryIso,
  });

  /// Null only when signed out meanwhile (the router is leaving).
  final UserProfile? profile;
  final Completeness? completeness;

  /// Shown when there is no photo.
  final SilhouetteStyle silhouette;

  /// Where the user lives, as answered.
  final String? city;
  final String? countryIso;
}
