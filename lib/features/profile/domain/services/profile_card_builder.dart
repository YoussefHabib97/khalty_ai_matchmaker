import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_card.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/silhouette_style.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/field_keys.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/services/questionnaire_engine.dart';

/// Builds the [ProfileCard] a suggested match sees. This is the one gate
/// between the profile and the card: only `card` answers pass, never
/// private (`khalty`) ones, Khalty's impressions, the brief or the
/// self-introduction.
abstract final class ProfileCardBuilder {
  /// Shown in the card's header instead of as answers.
  static const headerKeys = {
    FieldKeys.name,
    FieldKeys.age,
    FieldKeys.city,
    FieldKeys.country,
  };

  static ProfileCard of(UserProfile profile, QuestionnaireEngine engine) {
    final answers = profile.answers;
    AnswerValue? effective(String key) => engine.effective(key, answers)?.value;

    final items = <int, List<CardItem>>{};
    for (final field in engine.fields) {
      if (field.visibility != FieldVisibility.card) continue;
      if (headerKeys.contains(field.key)) continue;
      final answer = engine.effective(field.key, answers);
      if (answer == null) continue;
      // Taken from another answer (job ← work status): already shown there.
      if (answer.sourceKey != field.key) continue;
      if (!_shows(answer.value)) continue;
      (items[field.chapter] ??= []).add(
        CardItem(field: field, value: answer.value),
      );
    }

    final cover = effective(
      profile.gender == Gender.male ? FieldKeys.beard : FieldKeys.hijab,
    );
    final main = profile.mainPhoto;
    final isMan = profile.gender == Gender.male;
    return ProfileCard(
      gender: profile.gender,
      name: profile.name,
      age: profile.age,
      city: switch (effective(FieldKeys.city)) {
        TextAnswer(:final text) => text,
        _ => null,
      },
      countryIso: switch (effective(FieldKeys.country)) {
        CountryAnswer(:final iso2) => iso2,
        _ => null,
      },
      silhouette: SilhouetteStyle.of(
        profile.gender,
        cover is ChoiceAnswer ? cover.optionId : null,
      ),
      // A woman's photo is shared only after she accepts.
      photo: isMan ? main : null,
      photoNote: switch ((main != null, isMan)) {
        (false, _) => CardPhotoNote.none,
        (true, true) => CardPhotoNote.visibleToSuggested,
        (true, false) when profile.sharePhotoWithMatch =>
          CardPhotoNote.sharedAfterAccept,
        (true, false) => CardPhotoNote.keptPrivate,
      },
      aboutMe: switch (profile.effectiveAboutMe?.trim()) {
        final text? when text.isNotEmpty => text,
        _ => null,
      },
      sections: [
        for (final chapter in engine.config.chapters)
          if (items[chapter.id] case final list?)
            CardSection(chapter: chapter, items: List.unmodifiable(list)),
      ],
    );
  }

  /// Skipped answers, "no second nationality" and non-applicable ones say
  /// nothing about the person, so they stay off the card.
  static bool _shows(AnswerValue value) => switch (value) {
    SkippedAnswer() || NoneAnswer() || NotApplicable() => false,
    _ => true,
  };
}
