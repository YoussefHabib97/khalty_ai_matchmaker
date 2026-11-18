import 'package:khalty_ai_matchmaker/core/constants/enums.dart';

/// The faceless figure shown when there is no photo. Never has eyes or
/// facial features.
enum SilhouetteStyle {
  /// Men without a beard; women without hijab.
  plain,
  fullBeard,
  trimmedBeard,
  hijab,
  niqab;

  /// The style for a user of [gender] whose beard (men) or hijab (women)
  /// answer is the option [coverOptionId] (null when not asked or
  /// unanswered). "Hijab sometimes" shows a hijab.
  static SilhouetteStyle of(Gender gender, String? coverOptionId) =>
      switch ((gender, coverOptionId)) {
        (Gender.male, 'full_beard') => fullBeard,
        (Gender.male, 'trimmed_beard') => trimmedBeard,
        (Gender.female, 'niqab') => niqab,
        (Gender.female, 'hijab' || 'hijab_sometimes') => hijab,
        _ => plain,
      };
}
