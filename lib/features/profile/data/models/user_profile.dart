import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/core/utils/collections.dart';
import 'package:khalty_ai_matchmaker/core/utils/json_dates.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/intake_analysis.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/profile_photo.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/models/self_intro.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answer_value.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/answers.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/models/field_keys.dart';

/// What the user agreed to at sign-up, and when.
class Consent {
  const Consent({required this.version, required this.acceptedAt});

  factory Consent.fromJson(Map<String, Object?> json) => Consent(
    version: (json['version'] as num).toInt(),
    acceptedAt: dateFromJson(json['acceptedAt']),
  );

  /// Version of the consent text the user accepted.
  final int version;
  final DateTime acceptedAt;

  Map<String, Object?> toJson() => {
    'version': version,
    'acceptedAt': dateToJson(acceptedAt),
  };

  @override
  bool operator ==(Object other) =>
      other is Consent &&
      other.version == version &&
      other.acceptedAt == acceptedAt;
  @override
  int get hashCode => Object.hash(version, acceptedAt);
}

/// When each onboarding milestone was reached. The current onboarding stage
/// is derived from these plus the answers; it is never stored itself.
class OnboardingProgress {
  const OnboardingProgress({
    this.intakeDoneAt,
    this.selfIntroDoneAt,
    this.confirmedAt,
  });

  factory OnboardingProgress.fromJson(Map<String, Object?>? json) =>
      OnboardingProgress(
        intakeDoneAt: nullableDateFromJson(json?['intakeDoneAt']),
        selfIntroDoneAt: nullableDateFromJson(json?['selfIntroDoneAt']),
        confirmedAt: nullableDateFromJson(json?['confirmedAt']),
      );

  final DateTime? intakeDoneAt;
  final DateTime? selfIntroDoneAt;

  /// The user tapped "That's me" on the summary; onboarding is complete.
  final DateTime? confirmedAt;

  OnboardingProgress copyWith({
    Object? intakeDoneAt = _unset,
    Object? selfIntroDoneAt = _unset,
    Object? confirmedAt = _unset,
  }) => OnboardingProgress(
    intakeDoneAt: _pick(intakeDoneAt, this.intakeDoneAt),
    selfIntroDoneAt: _pick(selfIntroDoneAt, this.selfIntroDoneAt),
    confirmedAt: _pick(confirmedAt, this.confirmedAt),
  );

  Map<String, Object?> toJson() => {
    'intakeDoneAt': nullableDateToJson(intakeDoneAt),
    'selfIntroDoneAt': nullableDateToJson(selfIntroDoneAt),
    'confirmedAt': nullableDateToJson(confirmedAt),
  };

  @override
  bool operator ==(Object other) =>
      other is OnboardingProgress &&
      other.intakeDoneAt == intakeDoneAt &&
      other.selfIntroDoneAt == selfIntroDoneAt &&
      other.confirmedAt == confirmedAt;
  @override
  int get hashCode => Object.hash(intakeDoneAt, selfIntroDoneAt, confirmedAt);
}

/// The signed-in user's own profile: everything onboarding collects plus
/// what they edit later. Persisted as JSON with a schema version.
class UserProfile {
  UserProfile({
    required this.uid,
    required this.gender,
    required this.phoneE164,
    required this.consent,
    Answers? answers,
    this.selfIntro,
    this.analysis,
    this.aboutMe,
    List<ProfilePhoto> photos = const [],
    this.sharePhotoWithMatch = false,
    this.paused = false,
    this.progress = const OnboardingProgress(),
  }) : answers = answers ?? Answers(),
       photos = List.unmodifiable(photos) {
    if (photos.length > maxPhotos) {
      throw ArgumentError('At most $maxPhotos photos, got ${photos.length}');
    }
  }

  /// Parses persisted JSON (upgrading older schemas via [migrate]).
  /// Throws [FormatException] if it is unusable.
  factory UserProfile.fromJson(Map<String, Object?> json) {
    final data = migrate(json);
    try {
      return UserProfile(
        uid: data['uid'] as String,
        gender: Gender.fromName(data['gender']),
        phoneE164: data['phone'] as String,
        consent: Consent.fromJson(_map(data['consent'])!),
        answers: Answers.fromJson(data['answers']),
        selfIntro: _map(data['selfIntro']) == null
            ? null
            : SelfIntro.fromJson(_map(data['selfIntro'])!),
        analysis: _map(data['analysis']) == null
            ? null
            : IntakeAnalysis.fromJson(_map(data['analysis'])!),
        aboutMe: data['aboutMe'] as String?,
        photos: [
          for (final p in (data['photos'] as List? ?? const []))
            ProfilePhoto.fromJson(_map(p)!),
        ],
        sharePhotoWithMatch: data['sharePhotoWithMatch'] as bool? ?? false,
        paused: data['paused'] as bool? ?? false,
        progress: OnboardingProgress.fromJson(_map(data['progress'])),
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed profile JSON: $e');
    }
  }

  static const schemaVersion = 1;
  static const maxPhotos = 3;

  /// Upgrades persisted JSON from any older schema to [schemaVersion].
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

  final String uid;
  final Gender gender;
  final String phoneE164;
  final Consent consent;
  final Answers answers;
  final SelfIntro? selfIntro;
  final IntakeAnalysis? analysis;

  /// The bio as edited by the user (sanitised before saving). Null until the
  /// user edits it; see [effectiveAboutMe].
  final String? aboutMe;

  /// Index 0 is the main photo. At most [maxPhotos].
  final List<ProfilePhoto> photos;

  /// Women only: share the main photo with a match after accepting.
  final bool sharePhotoWithMatch;
  final bool paused;
  final OnboardingProgress progress;

  /// The user's edited bio, or Khalty's suggested one.
  String? get effectiveAboutMe => aboutMe ?? analysis?.aboutMe;

  String? get name => switch (answers[FieldKeys.name]) {
    TextAnswer(:final text) => text,
    _ => null,
  };

  int? get age => switch (answers[FieldKeys.age]) {
    NumberAnswer(:final value) => value,
    _ => null,
  };

  ProfilePhoto? get mainPhoto => photos.isEmpty ? null : photos.first;

  /// Nullable fields can be cleared by passing `null` explicitly.
  UserProfile copyWith({
    Gender? gender,
    String? phoneE164,
    Consent? consent,
    Answers? answers,
    Object? selfIntro = _unset,
    Object? analysis = _unset,
    Object? aboutMe = _unset,
    List<ProfilePhoto>? photos,
    bool? sharePhotoWithMatch,
    bool? paused,
    OnboardingProgress? progress,
  }) => UserProfile(
    uid: uid,
    gender: gender ?? this.gender,
    phoneE164: phoneE164 ?? this.phoneE164,
    consent: consent ?? this.consent,
    answers: answers ?? this.answers,
    selfIntro: _pick(selfIntro, this.selfIntro),
    analysis: _pick(analysis, this.analysis),
    aboutMe: _pick(aboutMe, this.aboutMe),
    photos: photos ?? this.photos,
    sharePhotoWithMatch: sharePhotoWithMatch ?? this.sharePhotoWithMatch,
    paused: paused ?? this.paused,
    progress: progress ?? this.progress,
  );

  Map<String, Object?> toJson() => {
    'schema': schemaVersion,
    'uid': uid,
    'gender': gender.name,
    'phone': phoneE164,
    'consent': consent.toJson(),
    'answers': answers.toJson(),
    'selfIntro': selfIntro?.toJson(),
    'analysis': analysis?.toJson(),
    'aboutMe': aboutMe,
    'photos': [for (final p in photos) p.toJson()],
    'sharePhotoWithMatch': sharePhotoWithMatch,
    'paused': paused,
    'progress': progress.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.uid == uid &&
      other.gender == gender &&
      other.phoneE164 == phoneE164 &&
      other.consent == consent &&
      other.answers == answers &&
      other.selfIntro == selfIntro &&
      other.analysis == analysis &&
      other.aboutMe == aboutMe &&
      listEquals(other.photos, photos) &&
      other.sharePhotoWithMatch == sharePhotoWithMatch &&
      other.paused == paused &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
    uid,
    gender,
    phoneE164,
    consent,
    answers,
    selfIntro,
    analysis,
    aboutMe,
    Object.hashAll(photos),
    sharePhotoWithMatch,
    paused,
    progress,
  );
}

const _unset = Object();

T? _pick<T>(Object? value, T? current) =>
    identical(value, _unset) ? current : value as T?;

Map<String, Object?>? _map(Object? json) =>
    json is Map ? Map<String, Object?>.from(json) : null;
