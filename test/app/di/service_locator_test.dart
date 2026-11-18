import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khalty_ai_matchmaker/app/debug/debug_stage_actions.dart';
import 'package:khalty_ai_matchmaker/app/di/service_locator.dart';
import 'package:khalty_ai_matchmaker/app/session/session_cubit.dart';
import 'package:khalty_ai_matchmaker/features/auth/data/repos/fake_auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/domain/repos/auth_repository.dart';
import 'package:khalty_ai_matchmaker/features/auth/presentation/manager/sign_up_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/intake_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/review_cubit.dart';
import 'package:khalty_ai_matchmaker/features/intake/presentation/manager/self_intro_cubit.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/data/repos/fake_khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/khalty_ai/domain/repos/khalty_ai_repository.dart';
import 'package:khalty_ai_matchmaker/features/onboarding/domain/services/onboarding_stage_resolver.dart';
import 'package:khalty_ai_matchmaker/features/profile/data/repos/local_profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/domain/repos/profile_repository.dart';
import 'package:khalty_ai_matchmaker/features/profile/presentation/manager/me_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/account_cubit.dart';
import 'package:khalty_ai_matchmaker/core/utils/shared_preferences.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/data/repos/asset_questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/entities/questionnaire_config.dart';
import 'package:khalty_ai_matchmaker/features/questionnaire/domain/repos/questionnaire_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/data/repos/local_settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/domain/repos/settings_repository.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/locale_cubit.dart';
import 'package:khalty_ai_matchmaker/features/settings/presentation/manager/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Needed to load the questionnaire asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });
  tearDown(() => getIt.reset());

  test('every registration resolves', () {
    expect(getIt<SharedPreferences>(), isNotNull);
    expect(getIt<SharedPrefs>(), isNotNull);
    expect(getIt<QuestionnaireConfig>().fields, isNotEmpty);
    expect(getIt<AppThemeCubit>(), isNotNull);
    expect(getIt<LocaleCubit>(), isNotNull);
    expect(identical(getIt<SignUpCubit>(), getIt<SignUpCubit>()), isFalse);
    expect(identical(getIt<IntakeCubit>(), getIt<IntakeCubit>()), isFalse);
    expect(
      identical(getIt<SelfIntroCubit>(), getIt<SelfIntroCubit>()),
      isFalse,
    );
    expect(identical(getIt<ReviewCubit>(), getIt<ReviewCubit>()), isFalse);
    expect(identical(getIt<MeCubit>(), getIt<MeCubit>()), isFalse);
    expect(identical(getIt<AccountCubit>(), getIt<AccountCubit>()), isFalse);
  });

  test('repositories are registered by interface', () {
    expect(getIt<SettingsRepository>(), isA<LocalSettingsRepository>());
    expect(
      getIt<QuestionnaireRepository>(),
      isA<AssetQuestionnaireRepository>(),
    );
    expect(getIt<AuthRepository>(), isA<FakeAuthRepository>());
    expect(getIt<ProfileRepository>(), isA<LocalProfileRepository>());
    expect(getIt<KhaltyAiRepository>(), isA<FakeKhaltyAiRepository>());
  });

  test('the session, router and debug actions are app-wide singletons', () {
    expect(identical(getIt<SessionCubit>(), getIt<SessionCubit>()), isTrue);
    expect(identical(getIt<GoRouter>(), getIt<GoRouter>()), isTrue);
    expect(getIt<OnboardingStageResolver>(), isNotNull);
    expect(getIt<DebugStageActions>(), isNotNull); // tests run in debug mode
  });

  test('services are singletons, cubits are new instances', () {
    expect(identical(getIt<SharedPrefs>(), getIt<SharedPrefs>()), isTrue);
    expect(
      identical(getIt<SettingsRepository>(), getIt<SettingsRepository>()),
      isTrue,
    );
    expect(
      identical(getIt<QuestionnaireConfig>(), getIt<QuestionnaireConfig>()),
      isTrue,
    );
    expect(identical(getIt<AppThemeCubit>(), getIt<AppThemeCubit>()), isFalse);
    expect(identical(getIt<LocaleCubit>(), getIt<LocaleCubit>()), isFalse);
  });
}
