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

Widget tests that pump `ApplicationRoot` need `SharedPreferences.setMockInitialValues(...)`, then `await tester.runAsync(setupServiceLocator)` (it loads an asset; real I/O hangs on the fake test clock otherwise) with `addTearDown(getIt.reset)`, and a phone-sized `tester.view` because of `ScreenUtilPlusInit` (see `test/widget_test.dart`). Unit tests construct classes directly with injected fakes instead of using the locator (e.g. `test/helpers/fake_settings_repository.dart` for cubits, `test/helpers/prefs.dart` for a mock-backed `SharedPrefs`).

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
- **Dependency injection (get_it):** `lib/app/di/service_locator.dart` is the composition root: the global `getIt` and `setupServiceLocator()`, the only place that chooses implementations. Data sources and repositories are **singletons registered by their interface type** (e.g. `SettingsRepository` → `LocalSettingsRepository`); cubits are **factories** provided via `BlocProvider(create: (_) => getIt<X>())` — never register a cubit as a singleton, because `BlocProvider` closes it. Classes receive dependencies through constructors; only the composition root and `BlocProvider`s call `getIt`. `SharedPrefs` (`core/utils/shared_preferences.dart`) is a feature-agnostic data source used only by data-layer repositories.
- **App root (`lib/app/app.dart`):** `ApplicationRoot` wraps everything in `ScreenUtilPlusInit` (design size 375×812 — size with `.w` / `.h` / `.sp`), provides `AppThemeCubit` and `LocaleCubit`, and builds `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark`.
- **Settings (theme, language):** `features/settings/`. `SettingsRepository` (domain interface) is implemented by `LocalSettingsRepository` (keys `themeKey`, `localeKey`). `AppThemeCubit`'s state is a `ThemePreference` (`deviceDefault`/`light`/`dark`), exposed to `MaterialApp` as `themeMode`. Colors/`ThemeData` are defined only in `core/theme/app_colors.dart`, `app_theme.dart` and `text_theme.dart`.
- **Routing:** `createAppRouter()` in `lib/app/navigation/app_router.dart` builds the `GoRouter`; `ApplicationRoot` creates it once and keeps the instance (never make it static or rebuild it). Route paths are `static const` strings on `AppRoutes`. `/` currently maps to `OnboardingView`.
- **Localization (EN/AR, RTL):** gen-l10n configured by `l10n.yaml`. UI strings go in **both** `lib/core/l10n/arb/app_en.arb` (template, with `@key` descriptions) and `app_ar.arb`; regenerate with `fvm flutter gen-l10n` (also runs on `pub get`/`run`). Read them via `context.l10n.<key>` (`core/l10n/l10n_extensions.dart`). Gendered Arabic uses ICU `{gender, select, male{…} female{…} other{…}}`, where `other` is the neutral text before the user picks a gender. Generated code in `lib/core/l10n/generated/` is committed and excluded from the analyzer; never edit it by hand. `MaterialApp` takes `[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` from `material_ui` — don't use the generated `localizationsDelegates` list (it pulls the deprecated flutter_localizations Material delegate). `LocaleCubit` saves the language through `SettingsRepository`; first run follows the device language (Arabic) else English. RTL follows the locale automatically, so use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end) rather than left/right. Questionnaire texts (and Khalty's questionnaire lines) live in the config JSON, not in ARB.
- **Questionnaire config:** `assets/config/questionnaire.json` (schema v2; its `_readme` explains the format) is loaded once at startup by `AssetQuestionnaireRepository` and registered in get_it as `QuestionnaireConfig` (domain entity). `QuestionnaireConfigParser` (`features/questionnaire/data/models/`) validates strictly (unknown properties, missing en/ar or gendered variants, unknown `{placeholders}`, conditions referencing later fields or unknown option ids, bounds, etc.), throwing `ConfigException` with the exact path. Answers store option **ids**, so never change or reuse a live id; labels can change freely. Texts resolve by the **user's** gender. Field keys used directly in code are constants in `FieldKeys`; `test/features/questionnaire/data/questionnaire_asset_test.dart` checks the real file, so edit the JSON and run tests. Old AI prompts for the future real AI are in `docs/ai_prompts.md`.
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
