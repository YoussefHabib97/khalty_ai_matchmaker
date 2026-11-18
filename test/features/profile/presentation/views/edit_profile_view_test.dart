import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/core/constants/enums.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/views/review_view.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/entities/onboarding_stage.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/photo_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/edit_profile_view.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/views/me_view.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/answer_value.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/app.dart';
import '../../../../helpers/fake_photo_repository.dart';
import '../../../../helpers/questionnaire.dart';
import '../../../../helpers/session.dart';

void main() {
  final config = loadRealConfig();

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens Edit my profile from the Me tab, with fake photos.
  Future<void> openEdit(WidgetTester tester) async {
    await pumpApp(
      tester,
      storedSessionAt(OnboardingStage.complete),
      beforeStart: () => getIt
        ..unregister<PhotoRepository>()
        ..registerSingleton<PhotoRepository>(FakePhotoRepository()),
    );
    await tap(tester, find.byIcon(Icons.person_outline).first);
    await tap(tester, find.byKey(const Key('editProfile')));
    expect(find.byType(EditProfileView), findsOneWidget);
  }

  /// Scrolls the edit list until [finder] is built and visible.
  Future<void> reveal(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find
            .descendant(
              of: find.byType(EditProfileView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  AnswerValue? saved(String key) =>
      getIt<ProfileRepository>().current!.answers[key];

  /// Leaves the edit screen, waiting for the fake AI's brief refresh (2 s).
  Future<void> leave(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('edit an answer; Me and the brief follow', (tester) async {
    await openEdit(tester);
    await reveal(tester, find.byKey(const Key('edit-age')));
    await tap(tester, find.byKey(const Key('edit-age')));
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '31',
    );
    await tap(tester, find.byKey(const Key('answerSubmit')));
    expect(saved('age'), const NumberAnswer(31));
    expect(find.byType(BottomSheet), findsNothing);

    await leave(tester);
    expect(find.byType(MeView), findsOneWidget);
    expect(find.textContaining('31 years'), findsOneWidget);
    expect(getIt<ProfileRepository>().current!.analysis!.brief, contains('31'));
  });

  testWidgets('a question that now applies is asked right away', (
    tester,
  ) async {
    await openEdit(tester);
    await reveal(tester, find.byKey(const Key('edit-marital_status')));
    await tap(tester, find.byKey(const Key('edit-marital_status')));
    await tap(tester, find.byKey(const Key('option-divorced')));

    expect(find.text('This question now applies to you.'), findsOneWidget);
    final firstChildrenOption = config
        .field('children_now')!
        .optionsFor(Gender.female)
        .first
        .id;
    await tap(tester, find.byKey(Key('option-$firstChildrenOption')));
    expect(saved('marital_status'), const ChoiceAnswer('divorced'));
    expect(saved('children_now'), ChoiceAnswer(firstChildrenOption));
  });

  testWidgets('About me: contact details removed, and the user is told', (
    tester,
  ) async {
    await openEdit(tester);
    await tap(tester, find.byKey(const Key('editAboutMe')));
    await tester.enterText(
      find.byKey(const Key('aboutMeField')),
      'I teach children. Call 0501234567.',
    );
    await tap(tester, find.byKey(const Key('aboutMeSave')));

    expect(
      find.text('Contact details were removed: Khalty introduces you first.'),
      findsOneWidget,
    );
    expect(
      getIt<ProfileRepository>().current!.aboutMe,
      isNot(contains('0501234567')),
    );
  });

  testWidgets('About me: leaving unsaved changes asks first', (tester) async {
    await openEdit(tester);
    await tap(tester, find.byKey(const Key('editAboutMe')));
    await tester.enterText(find.byKey(const Key('aboutMeField')), 'Draft');
    await tap(tester, find.byKey(const Key('aboutMeCancel')));
    expect(find.text('Discard your changes?'), findsOneWidget);

    await tap(tester, find.text('Keep editing'));
    expect(find.byKey(const Key('aboutMeField')), findsOneWidget);

    await tap(tester, find.byKey(const Key('aboutMeCancel')));
    await tap(tester, find.byKey(const Key('confirmDiscard')));
    expect(find.byKey(const Key('aboutMeField')), findsNothing);
    expect(getIt<ProfileRepository>().current!.aboutMe, isNull);
  });

  testWidgets('photos: add, the first is main; women can share', (
    tester,
  ) async {
    await openEdit(tester);
    await tap(tester, find.byKey(const Key('photoSlot-0')));
    await tap(tester, find.byKey(const Key('photoFromGallery')));
    expect(find.byKey(const Key('photo-0')), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(getIt<ProfileRepository>().current!.photos, hasLength(1));

    await tap(tester, find.byKey(const Key('sharePhoto')));
    expect(getIt<ProfileRepository>().current!.sharePhotoWithMatch, isTrue);
  });

  testWidgets('from the review, "Change an answer" opens editing', (
    tester,
  ) async {
    await pumpApp(tester, storedSessionAt(OnboardingStage.needsReview));
    await tap(tester, find.byKey(const Key('reviewEdit')));
    await tap(tester, find.byKey(const Key('reviewChangeAnswers')));
    expect(find.byType(EditProfileView), findsOneWidget);

    await leave(tester);
    expect(find.byType(ReviewView), findsOneWidget);
  });
}
