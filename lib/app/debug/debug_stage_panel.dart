import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_actions.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/app/session/session_state.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:material_ui/material_ui.dart';

/// DEBUG ONLY (removed in step 13): a strip under each screen with buttons
/// that move to the next onboarding stage. English only on purpose.
class DebugStagePanel extends StatelessWidget {
  const DebugStagePanel({
    super.key,
    required this.actions,
    required this.child,
  });

  final DebugStageActions actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: child),
      BlocBuilder<SessionCubit, SessionState>(
        builder: (context, session) => Material(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('DEBUG · ${session.stage.name}'),
                  ..._buttons(session.stage),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  List<Widget> _buttons(OnboardingStage stage) {
    Widget button(String label, Future<void> Function() onPressed) =>
        FilledButton.tonal(onPressed: onPressed, child: Text(label));
    return [
      ...switch (stage) {
        OnboardingStage.needsSignUp => [
          button('Sign in (man)', () => actions.signIn(Gender.male)),
          button('Sign in (woman)', () => actions.signIn(Gender.female)),
        ],
        OnboardingStage.needsIntake => [
          button('Answer all', actions.answerAll),
        ],
        OnboardingStage.needsSelfIntro => [
          button('Add self-intro', actions.addSelfIntro),
        ],
        OnboardingStage.needsReview => [button('Confirm', actions.confirm)],
        OnboardingStage.complete => const <Widget>[],
      },
      if (stage != OnboardingStage.needsSignUp) button('Reset', actions.reset),
    ];
  }
}
