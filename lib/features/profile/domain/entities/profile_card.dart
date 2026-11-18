import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

/// What the photo area of the card tells the user in the preview.
enum CardPhotoNote {
  /// No photos: the silhouette is all anyone sees.
  none,

  /// Men: suggested women see the main photo.
  visibleToSuggested,

  /// Women: the silhouette until she accepts; then her main photo.
  sharedAfterAccept,

  /// Women with photos who don't share them: only the silhouette.
  keptPrivate,
}

/// One answer on the card, e.g. "Prayer · All five, on time".
class CardItem {
  const CardItem({required this.field, required this.value});

  /// The question: its `label` names the answer, its options describe it.
  final FieldDef field;
  final AnswerValue value;
}

/// The card's answers from one chapter.
class CardSection {
  const CardSection({required this.chapter, required this.items});

  final ChapterDef chapter;
  final List<CardItem> items;
}

/// The profile card a suggested match sees. Built only by
/// `ProfileCardBuilder`, which leaves out every private answer.
class ProfileCard {
  const ProfileCard({
    required this.gender,
    required this.silhouette,
    required this.photoNote,
    required this.sections,
    this.name,
    this.age,
    this.city,
    this.countryIso,
    this.photo,
    this.aboutMe,
  });

  final Gender gender;
  final String? name;
  final int? age;
  final String? city;
  final String? countryIso;

  /// Shown when [photo] is null.
  final SilhouetteStyle silhouette;

  /// The photo the match sees before accepting; null shows the silhouette.
  final ProfilePhoto? photo;
  final CardPhotoNote photoNote;

  /// The bio; null when there is none.
  final String? aboutMe;
  final List<CardSection> sections;
}
