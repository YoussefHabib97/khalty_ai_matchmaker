import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/app.dart';
import 'package:khalty_ai_matchmaker/app/di/app_dependencies.dart';
import 'package:khalty_ai_matchmaker/core/shared/widgets/theme_switcher_widget.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App starts on the onboarding view', (tester) async {
    tester.view.physicalSize = const Size(375, 812) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(ApplicationRoot(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.byType(ThemeSwitcherWidget), findsOneWidget);
  });
}
