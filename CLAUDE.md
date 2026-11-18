# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Toolchain

Flutter is pinned with FVM to **3.50.0** (`.fvmrc`); VS Code points at `.fvm/versions/3.50.0`. Run Flutter commands through FVM so the pinned SDK is used:

```sh
fvm flutter pub get
fvm flutter analyze                         # lints via flutter_lints; platform dirs are excluded
fvm flutter test                            # all tests
fvm flutter test test/widget_test.dart      # single file
fvm flutter test --plain-name "<test name>" # single test by name
fvm flutter run
```

Widget tests that pump `ApplicationRoot` need `SharedPreferences.setMockInitialValues(...)`, then `await tester.runAsync(setupServiceLocator)` (it loads an asset; real I/O hangs on the fake test clock otherwise) with `addTearDown(getIt.reset)`, and a phone-sized `tester.view` because of `ScreenUtilPlusInit` (`test/helpers/app.dart` `pumpApp` does all of this; `test/helpers/session.dart` `storedSession(profile)` / `storedSessionAt(stage)` give stored data for any onboarding point). Unit tests construct classes directly with injected fakes instead of using the locator (e.g. `test/helpers/fake_settings_repository.dart` for cubits, `test/helpers/prefs.dart` for a mock-backed `SharedPrefs`).

## Branches

`main` holds committed baselines; day-to-day work happens on `dev` (branched from `main`).

## Architecture

**MVVM with a domain layer** (feature-first). Each feature has three layers and dependencies point **inward only**:

```text
presentation  ──►  domain  ◄──  data
```

- **presentation** (`views/`, `widgets/`, `manager/`): Views are widgets that only render and forward events; ViewModels are cubits in `manager/` (state = what the view shows). Cubits depend on domain entities, services and repository **interfaces** only.
- **domain** (`entities/`, `repos/`, `services/`): pure Dart (no Flutter, no storage/network, no JSON except `AnswerValue`'s own stored form). Entities are immutable with value equality; `repos/` holds repository interfaces; `services/` holds real business logic (e.g. the questionnaire engine). No one-class-per-use-case: simple load/save goes straight from cubit to repository interface; add a service only when there is real logic.
- **data** (`datasources/`, `models/`, `repos/`): repository implementations, JSON parsing/mapping (mappers, parsers, migrations) and data sources (asset bundle, `SharedPrefs`, later Firebase). Nothing outside `data/` touches storage. Switching to Firebase = new implementations here + new registrations.

SOLID in practice: one responsibility per class (entity vs mapper vs repository vs cubit); config-driven questions are open for extension without code changes; fakes and real implementations must honour the same interface (tests prove it); small focused repository interfaces (`SettingsRepository`, `QuestionnaireRepository`, …); depend on interfaces, wired only in the composition root.

- **Material import:** UI files import `package:material_ui/material_ui.dart` instead of `package:flutter/material.dart`. Follow this in new files.
- **Startup (`lib/main.dart`):** locks portrait orientation, then `await setupServiceLocator()` before `runApp(const ApplicationRoot())`. Everything resolved from `getIt` depends on this having run.
- **Dependency injection (get_it):** `lib/app/di/service_locator.dart` is the composition root: the global `getIt` and `setupServiceLocator()`, the only place that chooses implementations. Data sources and repositories are **singletons registered by their interface type** (e.g. `SettingsRepository` → `LocalSettingsRepository`); screen cubits are **factories** provided via `BlocProvider(create: (_) => getIt<X>())` — never register a screen cubit as a singleton, because `BlocProvider` closes it. Exception: app-wide ViewModels that outlive every screen (`SessionCubit`) and the `GoRouter` are singletons, provided with `BlocProvider.value`. Classes receive dependencies through constructors; only the composition root and `BlocProvider`s call `getIt`. `SharedPrefs` (`core/utils/shared_preferences.dart`) is a feature-agnostic data source used only by data-layer repositories.
- **App root (`lib/app/app.dart`):** `ApplicationRoot` wraps everything in `ScreenUtilPlusInit` (design size 375×812 — size with `.w` / `.h` / `.sp`), provides `AppThemeCubit` and `LocaleCubit`, and builds `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark`.
- **Settings (theme, language):** `features/settings/`. `SettingsRepository` (domain interface) is implemented by `LocalSettingsRepository` (keys `themeKey`, `localeKey`). `AppThemeCubit`'s state is a `ThemePreference` (`deviceDefault`/`light`/`dark`), exposed to `MaterialApp` as `themeMode`. Colors/`ThemeData` are defined only in `core/theme/app_colors.dart`, `app_theme.dart` and `text_theme.dart`.
- **Session and routing:** `SessionCubit` (`lib/app/session/`) combines `AuthRepository.currentUser` and `ProfileRepository.current` into an `OnboardingStage` (`needsSignUp` → `needsIntake` → `needsSelfIntro` → `needsReview` → `complete`), computed by `OnboardingStageResolver` (`features/onboarding/domain/services/`) and **never stored**. Confirmed users stay `complete` even if questions are added later. The `GoRouter` is built by `createAppRouter(session)` (`lib/app/navigation/app_router.dart`) and re-runs its redirect on every session change; `resolveRedirect(stage, location)` (`redirect.dart`) is a pure function: each stage may only visit its own routes (`AppRoutes`), anything else goes to `homeForStage(stage)`. Finished users get a `StatefulShellRoute.indexedStack` with `MainShell` (Khalty · Matches · Chats · Me). `main()` passes the router and session (get_it singletons) into `ApplicationRoot`.
- **Screens don't know routes:** views take navigation as callbacks (e.g. `WelcomeView(onGetStarted:)`, `SignUpView(onCodeSent:)`) and `createAppRouter` wires them to `context.push/go/pop`. Never import `app/navigation` from a feature. Flows that span several screens share one cubit through a `ShellRoute` (sign-up + code entry share `SignUpCubit`, created via a factory passed into `createAppRouter`).
- **Countries and phone numbers:** `core/constants/countries.dart` (245 countries, EN/AR names, dial codes; generated once from MIT data, hand-edited since; keep the attribution header), `core/utils/country_search.dart` + `search_text.dart` (spelling-tolerant EN/AR search), `core/utils/phone_numbers.dart` (`toE164`), `core/utils/device_country.dart` (country from the phone's region settings, never from a dial code). The shared `showCountryPicker` sheet lives in `core/shared/widgets/`.
- **Auth and profile storage (local for now):** `FakeAuthRepository` accepts only code `123456` (same phone → same uid, session survives restarts); `LocalProfileRepository` stores the profile under `profile.v1` and backs up an unreadable one to `profile.v1.corrupt`. Signing out currently loses local data (no backend yet).
- **Debug stage panel (temporary, debug builds only, remove in step 13):** `lib/app/debug/` adds a strip under every screen (wired in `createAppRouter`) to fake sign-in, answer everything (`QuestionnaireAutofill`), add a self-intro, confirm, or reset. Its English-only texts are intentional.
- **Localization (EN/AR, RTL):** gen-l10n configured by `l10n.yaml`. UI strings go in **both** `lib/core/l10n/arb/app_en.arb` (template, with `@key` descriptions) and `app_ar.arb`; regenerate with `fvm flutter gen-l10n` (also runs on `pub get`/`run`). Read them via `context.l10n.<key>` (`core/l10n/l10n_extensions.dart`). Gendered Arabic uses ICU `{gender, select, male{…} female{…} other{…}}`, where `other` is the neutral text before the user picks a gender. Generated code in `lib/core/l10n/generated/` is committed and excluded from the analyzer; never edit it by hand. `MaterialApp` takes `[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` from `material_ui` — don't use the generated `localizationsDelegates` list (it pulls the deprecated flutter_localizations Material delegate). `LocaleCubit` saves the language through `SettingsRepository`; first run follows the device language (Arabic) else English. RTL follows the locale automatically, so use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end) rather than left/right. Questionnaire texts (and Khalty's questionnaire lines) live in the config JSON, not in ARB.
- **Questionnaire config:** `assets/config/questionnaire.json` (schema v2; its `_readme` explains the format) is loaded once at startup by `AssetQuestionnaireRepository` and registered in get_it as `QuestionnaireConfig` (domain entity). `QuestionnaireConfigParser` (`features/questionnaire/data/models/`) validates strictly (unknown properties, missing en/ar or gendered variants, unknown `{placeholders}`, conditions referencing later fields or unknown option ids, bounds, etc.), throwing `ConfigException` with the exact path. Answers store option **ids**, so never change or reuse a live id; labels can change freely. Texts resolve by the **user's** gender. Field keys used directly in code are constants in `FieldKeys`; `test/features/questionnaire/data/questionnaire_asset_test.dart` checks the real file, so edit the JSON and run tests. Old AI prompts for the future real AI are in `docs/ai_prompts.md`.
- **Questionnaire engine:** `QuestionnaireEngine(config, gender)` (`features/questionnaire/domain/services/`) holds every questionnaire rule and is the only place to put them: applicability (`if`), derived answers computed on read (`else_value`, `else_from` with `sourceKey`, `NotApplicable`; never stored), `nextField` (also resume), `previousField` (Back), `validate`/`apply` (returns an `InvalidReason`; screens map reasons to messages), `missingAnswers`, `progress`, `suggestedRange`, `toAiPayload` (English labels). It is stateless — pass the current `Answers` — and is shared by intake and profile editing. Tests use the real config via `test/helpers/questionnaire.dart` (`loadRealConfig`, `fillAll`).
- **Intake (questionnaire screens):** `features/intake/`. `IntakeCubit` (factory, given `ProfileRepository` and `OnboardingStageResolver.engineFor`) shows a sealed `IntakeStep` — `GreetingStep` → (`ChapterIntroStep` when entering a chapter that has an `intro`) → `QuestionStep` → `DoneStep` — and **saves every answer immediately**, so resume is just `engine.nextField`. Forward after Back uses `engine.fieldAfter` (passes already answered questions); Back uses `previousField`. The last answer stamps `progress.intakeDoneAt`; the session then redirects, so `IntakeView` has no navigation callback. Khalty's short replies (`NameReply`, `GeneralReply(index)` cycling `script.acks`) show only after a fresh answer. Answer inputs live in `features/questionnaire/presentation/widgets/` (reused by profile editing): `TypedAnswerInput` (text/number), `ChoiceAnswerInput` and `OptionCard`, `MultiAnswerInput` (chips disable at `max_pick`; own entries when `allow_text`, matched to an option's label first), `RangeAnswerInput`, `CountryAnswerInput` (confirm "Are you living in X?" or pick; optional form No/Yes+pick). Inputs that need a draft (text, multi, range) are answered with Continue; choices and countries on tap. `IntakeState.suggestedCountry` (earlier answer → residence for nationality → phone country) fills `{detected}`/`{residence}`; `suggestedRange` comes from `engine.suggestedRange`. `invalidAnswerText` maps `InvalidReason` to messages (a field's config `invalid` text wins for numbers). Widget tests drive the questionnaire through the UI with stable keys (`intakeContinue`, `intakeSkip`, `intakeIntroContinue`, `option-<id>`, `countryYes`/`countryOther`/`countryNone`/`countryPick`, `multiOwn`/`multiOwnAdd`).
- **Language switch widgets:** `LanguageSelector` (full dropdown, Welcome) and `LanguageMenuButton` (globe icon opening a menu, for app bars), both in `features/settings/presentation/widgets/`.
- **Profile storage:** `UserProfile` (domain) is stored via `UserProfileMapper` (data), which versions the JSON (`schema`) and upgrades older data in `migrate()`; bump `schemaVersion` and add a migration step whenever the stored shape changes.

## Folder conventions

- `lib/app/` — app root; `di/` (composition root), `navigation/` (router, shell), `session/` (app-wide session/onboarding state).
- `lib/core/` — shared, feature-agnostic code: `constants/` (incl. `Gender`, `AppLanguage`), `utils/` (SharedPrefs, digits, sanitizer, ids…; not `core/helpers/`), `l10n/` (ARB + generated), `theme/` (colors, ThemeData, text theme), `shared/layout/` and `shared/widgets/` (reusable UI).
- Features follow (create sub-folders only when they get files):

  ```text
  lib/features/<name>/
    presentation/{views,widgets,manager}   # cubits in manager/, beside views/, never inside it
    domain/{entities,repos,services}        # pure Dart; repos = interfaces
    data/{datasources,models,repos}         # implementations, mappers/parsers, storage
  ```

- Tests mirror `lib/` paths under `test/`; shared fakes and fixtures live in `test/helpers/`.
