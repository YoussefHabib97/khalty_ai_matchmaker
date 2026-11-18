import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/json_dates.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/entities/user_profile.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answers_mapper.dart';

/// Converts [UserProfile] to and from its stored JSON form, with a schema
/// version so stored data can be upgraded when the shape changes.
abstract final class UserProfileMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> toJson(UserProfile p) => {
    'schema': schemaVersion,
    'uid': p.uid,
    'gender': p.gender.name,
    'phone': p.phoneE164,
    'consent': {
      'version': p.consent.version,
      'acceptedAt': dateToJson(p.consent.acceptedAt),
    },
    'answers': AnswersMapper.toJson(p.answers),
    'selfIntro': p.selfIntro == null ? null : _selfIntroToJson(p.selfIntro!),
    'analysis': p.analysis == null ? null : _analysisToJson(p.analysis!),
    'aboutMe': p.aboutMe,
    'photos': [for (final photo in p.photos) _photoToJson(photo)],
    'sharePhotoWithMatch': p.sharePhotoWithMatch,
    'paused': p.paused,
    'progress': {
      'intakeDoneAt': nullableDateToJson(p.progress.intakeDoneAt),
      'selfIntroDoneAt': nullableDateToJson(p.progress.selfIntroDoneAt),
      'confirmedAt': nullableDateToJson(p.progress.confirmedAt),
    },
  };

  /// Parses stored JSON, upgrading older schemas via [migrate].
  /// Throws [FormatException] if it is unusable.
  static UserProfile fromJson(Map<String, Object?> json) {
    final data = migrate(json);
    try {
      final consent = _map(data['consent'])!;
      final progress = _map(data['progress']);
      final selfIntro = _map(data['selfIntro']);
      final analysis = _map(data['analysis']);
      return UserProfile(
        uid: data['uid'] as String,
        gender: Gender.fromName(data['gender']),
        phoneE164: data['phone'] as String,
        consent: Consent(
          version: (consent['version'] as num).toInt(),
          acceptedAt: dateFromJson(consent['acceptedAt']),
        ),
        answers: AnswersMapper.fromJson(data['answers']),
        selfIntro: selfIntro == null ? null : _selfIntroFromJson(selfIntro),
        analysis: analysis == null ? null : _analysisFromJson(analysis),
        aboutMe: data['aboutMe'] as String?,
        photos: [
          for (final photo in (data['photos'] as List? ?? const []))
            _photoFromJson(_map(photo)!),
        ],
        sharePhotoWithMatch: data['sharePhotoWithMatch'] as bool? ?? false,
        paused: data['paused'] as bool? ?? false,
        progress: OnboardingProgress(
          intakeDoneAt: nullableDateFromJson(progress?['intakeDoneAt']),
          selfIntroDoneAt: nullableDateFromJson(progress?['selfIntroDoneAt']),
          confirmedAt: nullableDateFromJson(progress?['confirmedAt']),
        ),
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed profile JSON: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Invalid profile JSON: ${e.message}');
    }
  }

  /// Upgrades stored JSON from any older schema to [schemaVersion].
  /// Add one step per version bump, e.g. `if (v == 1) json = _v1ToV2(json);`.
  static Map<String, Object?> migrate(Map<String, Object?> json) {
    final version = json['schema'] ?? 1;
    if (version is! int || version < 1) {
      throw FormatException('Invalid profile schema: $version');
    }
    if (version > schemaVersion) {
      throw FormatException(
        'Profile saved by a newer app version (schema $version)',
      );
    }
    return json;
  }

  // --- parts -----------------------------------------------------------------

  static Map<String, Object?> _selfIntroToJson(SelfIntro s) => {
    'text': s.text,
    'source': s.source.name,
    'skipped': s.skipped,
    'at': dateToJson(s.at),
  };

  static SelfIntro _selfIntroFromJson(Map<String, Object?> json) {
    final at = dateFromJson(json['at']);
    if (json['skipped'] == true) return SelfIntro.skipped(at: at);
    final text = json['text'] as String;
    return SelfIntroSource.fromName(json['source']) == SelfIntroSource.voice
        ? SelfIntro.voice(text, at: at)
        : SelfIntro.typed(text, at: at);
  }

  static Map<String, Object?> _analysisToJson(IntakeAnalysis a) => {
    'aboutMe': a.aboutMe,
    'traits': [
      for (final t in a.traits) {'label': t.label, 'reason': t.reason},
    ],
    'brief': a.brief,
    'mismatches': a.mismatches,
    'language': a.language.code,
    'generatedAt': dateToJson(a.generatedAt),
    'reply': a.reply,
  };

  static IntakeAnalysis _analysisFromJson(Map<String, Object?> json) =>
      IntakeAnalysis(
        aboutMe: json['aboutMe'] as String?,
        traits: [
          for (final t in (json['traits'] as List? ?? const []).take(
            IntakeAnalysis.maxTraits,
          ))
            Trait(
              label: (t as Map)['label'] as String,
              reason: t['reason'] as String,
            ),
        ],
        brief: json['brief'] as String,
        mismatches: List<String>.from(json['mismatches'] as List? ?? const []),
        language: AppLanguage.fromCode(json['language']),
        generatedAt: dateFromJson(json['generatedAt']),
        reply: json['reply'] as String?,
      );

  static Map<String, Object?> _photoToJson(ProfilePhoto p) => {
    'id': p.id,
    'localPath': p.localPath,
    'addedAt': dateToJson(p.addedAt),
  };

  static ProfilePhoto _photoFromJson(Map<String, Object?> json) => ProfilePhoto(
    id: json['id'] as String,
    localPath: json['localPath'] as String,
    addedAt: dateFromJson(json['addedAt']),
  );

  static Map<String, Object?>? _map(Object? json) =>
      json is Map ? Map<String, Object?>.from(json) : null;
}
