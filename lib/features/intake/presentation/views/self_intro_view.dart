import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:khalty_ai_matchmaker/core/shared/layout/app_default_padding.dart';
import 'package:khalty_ai_matchmaker/core/utils/extensions.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_state.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/khalty_bubble.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/widgets/user_bubble.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/widgets/language_menu_button.dart';
import 'package:material_ui/material_ui.dart';

/// The self-introduction, chat style: Khalty invites, the user writes (or
/// chooses "Not now"), Khalty puts everything together. Expects a
/// [SelfIntroCubit] above it. When the analysis is saved the session moves
/// on to the review, so this screen needs no navigation callback.
class SelfIntroView extends StatefulWidget {
  const SelfIntroView({super.key});

  /// Longest introduction accepted (about two minutes of speech).
  static const maxLength = 2000;

  @override
  State<SelfIntroView> createState() => _SelfIntroViewState();
}

class _SelfIntroViewState extends State<SelfIntroView> {
  late final TextEditingController _text = TextEditingController(
    text: context.read<SelfIntroCubit>().state.draft,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final cubit = context.read<SelfIntroCubit>();

    return BlocBuilder<SelfIntroCubit, SelfIntroState>(
      builder: (context, state) {
        final vars = {'name': ?state.name};
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(l10n.selfIntroTitle),
            actions: const [LanguageMenuButton()],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  // Reversed, like a chat: the newest message sits at the
                  // bottom and stays in view.
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      KhaltyBubble(
                        emphasised: false,
                        text: state.script.selfIntro.resolve(
                          language,
                          state.gender,
                          vars: vars,
                        ),
                      ),
                      if (state.sent case final sent?
                          when state.phase != SelfIntroPhase.writing) ...[
                        const SizedBox(height: 12),
                        UserBubble(text: sent),
                      ],
                      if (state.phase == SelfIntroPhase.analysing ||
                          state.phase == SelfIntroPhase.done) ...[
                        const SizedBox(height: 12),
                        KhaltyBubble(
                          emphasised: false,
                          text: state.script.analysing.resolve(
                            language,
                            state.gender,
                            vars: vars,
                          ),
                          footer: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ],
                      if (state.khaltyReply case final reply?) ...[
                        const SizedBox(height: 12),
                        KhaltyBubble(emphasised: false, text: reply),
                      ],
                      if (state.phase == SelfIntroPhase.failed) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.selfIntroFailed,
                          style: context.bodyMedium.copyWith(
                            color: colors.error,
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            key: const Key('selfIntroRetry'),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.tryAgain),
                            onPressed: () => cubit.retry(language),
                          ),
                        ),
                      ],
                    ].reversed.toList(),
                  ),
                ),
                if (state.canWrite) _composer(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _composer(BuildContext context, SelfIntroState state) {
    final l10n = context.l10n;
    final language = context.appLanguage;
    final cubit = context.read<SelfIntroCubit>();
    return DefaultPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          TextField(
            key: const Key('selfIntroField'),
            controller: _text,
            minLines: 3,
            maxLines: 8,
            maxLength: SelfIntroView.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.selfIntroHint,
              border: const OutlineInputBorder(),
            ),
          ),
          Row(
            children: [
              TextButton(
                key: const Key('selfIntroSkip'),
                onPressed: () => cubit.skip(language),
                child: Text(l10n.selfIntroSkip),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: _text,
                builder: (context, _) => FilledButton.icon(
                  key: const Key('selfIntroSend'),
                  icon: const Icon(Icons.send),
                  label: Text(l10n.selfIntroSend),
                  onPressed: _text.text.trim().isEmpty
                      ? null
                      : () => cubit.send(_text.text, language),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
