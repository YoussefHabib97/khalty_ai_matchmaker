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

Widget tests that pump `ApplicationRoot` need `SharedPreferences.setMockInitialValues(...)`, then `await tester.runAsync(setupServiceLocator)` (it loads an asset; real I/O hangs on the fake test clock otherwise) with `addTearDown(getIt.reset)`, and a phone-sized `tester.view` because of `ScreenUtilPlusInit` (see `test/widget_test.dart`). Unit tests construct classes directly with injected fakes instead of using the locator; `test/helpers/prefs.dart` gives a mock-backed `SharedPrefs`.

## Branches

`main` holds committed baselines; day-to-day work happens on `dev` (branched from `main`).

## Architecture

- **Material import:** UI files import `package:material_ui/material_ui.dart` instead of `package:flutter/material.dart`. Follow this in new files.
- **Startup (`lib/main.dart`):** locks portrait orientation, then `await setupServiceLocator()` before `runApp(const ApplicationRoot())`. Everything resolved from `getIt` depends on this having run.
- **Dependency injection (get_it):** `lib/app/di/service_locator.dart` defines the global `getIt` and `setupServiceLocator()`, the single place that registers dependencies and chooses implementations (local/fake now, Firebase later). Services and repositories are **singletons**; cubits are **factories** provided via `BlocProvider(create: (_) => getIt<X>())` — never register a cubit as a singleton, because `BlocProvider` closes it. Classes take their dependencies through constructors (e.g. `AppThemeCubit(SharedPrefs)`); only registration code and `BlocProvider`s call `getIt`. `SharedPrefs` (`core/utils/shared_preferences.dart`) is an injected instance wrapper around `SharedPreferences`, not a static helper.
- **App root (`lib/app/app.dart`):** `ApplicationRoot` wraps everything in `ScreenUtilPlusInit` (design size 375×812 — size with `.w` / `.h` / `.sp`), provides `AppThemeCubit`, and builds `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark`.
- **Theme flow:** `AppThemeCubit` (`core/theme/cubit/`) persists the chosen mode to `SharedPrefs` under `kAppThemeKey` and emits Light/Dark/DeviceDefault states. `ApplicationRoot` reads `cubit.themeMode`, which is derived from the stored pref (pref is written before each emit). Creating `SharedPrefs` runs the first-run check, which seeds the pref to device default. Theme keys and the `ThemeState` enum live in `core/constants/constants.dart`. Colors/`ThemeData` are defined only in `core/theme/app_colors.dart` and `app_theme.dart`.
- **Routing:** `createAppRouter()` in `lib/app/navigation/app_router.dart` builds the `GoRouter`; `ApplicationRoot` creates it once and keeps the instance (never make it static or rebuild it). Route paths are `static const` strings on `AppRoutes`. `/` currently maps to `OnboardingView`.
- **State management:** `flutter_bloc` cubits, one per screen/feature; all writes go through repositories.
- **Localization (EN/AR, RTL):** gen-l10n configured by `l10n.yaml`. UI strings go in **both** `lib/core/l10n/arb/app_en.arb` (template, with `@key` descriptions) and `app_ar.arb`; regenerate with `fvm flutter gen-l10n` (also runs on `pub get`/`run`). Read them via `context.l10n.<key>` (`core/l10n/l10n_extensions.dart`). Gendered Arabic uses ICU `{gender, select, male{…} female{…} other{…}}`, where `other` is the neutral text before the user picks a gender. Generated code in `lib/core/l10n/generated/` is committed and excluded from the analyzer; never edit it by hand. `MaterialApp` takes `[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` from `material_ui` — don't use the generated `localizationsDelegates` list (it pulls the deprecated flutter_localizations Material delegate). `LocaleCubit` persists the language under `kAppLocaleKey`; first run follows the device language (Arabic) else English. RTL follows the locale automatically, so use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end) rather than left/right. Questionnaire texts (and Khalty's questionnaire lines) live in the config JSON, not in ARB.
- **Questionnaire config:** `assets/config/questionnaire.json` (schema v2; its `_readme` explains the format) is loaded once at startup by `AssetQuestionnaireRepository` and registered in get_it as `QuestionnaireConfig`. `QuestionnaireConfig.fromJson` (`features/questionnaire/data/models/`) parses into typed models and validates strictly (unknown properties, missing en/ar or gendered variants, unknown `{placeholders}`, conditions referencing later fields or unknown option ids, bounds, etc.), throwing `ConfigException` with the exact path. Answers store option **ids**, so never change or reuse a live id; labels can change freely. Texts resolve by the **user's** gender. Field keys used directly in code are constants in `FieldKeys`; `test/features/questionnaire/data/questionnaire_asset_test.dart` checks the real file (counts, `FieldKeys`, private fields, new-field review flags), so edit the JSON and run tests. Old AI prompts for the future real AI are in `docs/ai_prompts.md`.

## Folder conventions

- `lib/app/` — app root; `di/` (service locator), `navigation/` (router, shell), `session/` (app-wide session/onboarding state).
- `lib/core/utils/` — SharedPrefs and other helpers (not `core/helpers/`).
- `lib/core/l10n/` — ARB files, generated localizations and the locale cubit.
- `lib/core/shared/layout/` and `lib/core/shared/widgets/` — reusable UI (e.g. `DefaultPadding`, `ThemeSwitcherWidget`).
- Features follow:
  ```
  lib/features/<name>/
    data/{models,repos}
    presentation/{views,widgets,manager}   # cubits go in manager/, beside views/, never inside it
  ```
  Create sub-folders only when they get files. Pure-Dart logic that a feature's data layer needs (e.g. the questionnaire engine) may live in `data/engine/`.
