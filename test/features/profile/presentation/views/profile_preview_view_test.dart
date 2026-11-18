import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/profile_preview_view.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/app.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens the preview from the Me tab.
  Future<void> openPreview(WidgetTester tester) async {
    await pumpApp(tester, storedSessionAt(OnboardingStage.complete));
    await tap(tester, find.byIcon(Icons.person_outline).first);
    await tap(tester, find.byKey(const Key('openPreview')));
    expect(find.byType(ProfilePreviewView), findsOneWidget);
  }

  testWidgets('shows the card answers, never the private ones', (tester) async {
    await openPreview(tester);
    expect(find.byKey(const Key('profileCard-en')), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Prayer'), findsOneWidget);
    expect(find.text('130 cm'), findsOneWidget);

    for (final field in config.fields) {
      final onCard = find.byKey(Key('card-${field.key}'), skipOffstage: false);
      if (field.visibility == FieldVisibility.khalty) {
        expect(onCard, findsNothing, reason: field.key);
      }
    }
    // The partner-age range ("25 to 35 years") is nowhere on screen.
    expect(find.textContaining(RegExp(r'\d+ to \d+')), findsNothing);
    expect(find.text('Brief'), findsNothing);
  });

  testWidgets('the card switches to Arabic, the screen stays English', (
    tester,
  ) async {
    await openPreview(tester);
    await tap(tester, find.byKey(const Key('previewIn-ar')));

    final card = find.byKey(const Key('profileCard-ar'));
    expect(card, findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);
    expect(Directionality.of(tester.element(card)), TextDirection.rtl);
    expect(find.text('See how Khalty presents you'), findsOneWidget);

    await tap(tester, find.byKey(const Key('previewIn-en')));
    expect(find.byKey(const Key('profileCard-en')), findsOneWidget);
  });
}
