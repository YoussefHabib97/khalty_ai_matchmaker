import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';

enum SelfIntroPhase {
  /// Writing (or about to skip).
  writing,

  /// Khalty is putting everything together.
  analysing,

  /// Khalty asked once for a better introduction; writing again.
  needsMore,

  /// The AI or saving failed; nothing was saved.
  failed,

  /// Saved; the app is moving on to the review.
  done,
}

/// Everything the self-introduction screen shows.
class SelfIntroState {
  const SelfIntroState({
    required this.phase,
    required this.gender,
    required this.script,
    this.name,
    this.draft = '',
    this.sent,
    this.khaltyReply,
  });

  final SelfIntroPhase phase;

  /// The user's gender, for gendered config texts.
  final Gender gender;

  /// Khalty's lines (the invitation and "let me put everything together").
  final ScriptTexts script;
  final String? name;

  /// Text to start the field with (an earlier introduction being rewritten,
  /// or the one Khalty asked to expand).
  final String draft;

  /// The introduction last sent (shown as the user's chat bubble); null
  /// when skipped or nothing sent yet.
  final String? sent;

  /// Khalty's request for more, in [SelfIntroPhase.needsMore].
  final String? khaltyReply;

  bool get canWrite =>
      phase == SelfIntroPhase.writing || phase == SelfIntroPhase.needsMore;

  SelfIntroState copyWith({
    SelfIntroPhase? phase,
    String? draft,
    Object? sent = _unset,
    Object? khaltyReply = _unset,
  }) => SelfIntroState(
    phase: phase ?? this.phase,
    gender: gender,
    script: script,
    name: name,
    draft: draft ?? this.draft,
    sent: identical(sent, _unset) ? this.sent : sent as String?,
    khaltyReply: identical(khaltyReply, _unset)
        ? this.khaltyReply
        : khaltyReply as String?,
  );
}

const _unset = Object();
