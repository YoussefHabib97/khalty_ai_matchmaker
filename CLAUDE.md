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

Known issue: `test/widget_test.dart` is the unmodified Flutter template and references `MyApp`, which does not exist (the root widget is `ApplicationRoot`), so the test suite does not compile until it is updated.

## Branches

`main` holds committed baselines; day-to-day work happens on `dev` (branched from `main`).

## Architecture

- **Material import:** UI files import `package:material_ui/material_ui.dart` instead of `package:flutter/material.dart`. Follow this in new files.
- **Startup (`lib/main.dart`):** locks portrait orientation, then `await SharedPrefs.init()` before `runApp`. Anything reading prefs synchronously (e.g. the theme) depends on this having run.
- **App root (`lib/app/app.dart`):** `ApplicationRoot` wraps everything in `ScreenUtilPlusInit` (design size 375×812 — size with `.w` / `.h` / `.sp`), provides `AppThemeCubit`, and builds `MaterialApp.router` with `AppTheme.light` / `AppTheme.dark`.
- **Theme flow:** `AppThemeCubit` (`core/theme/cubit/`) persists the chosen mode to `SharedPrefs` under `kAppThemeKey` and emits Light/Dark/DeviceDefault states. Its initial state carries no mode, so `ApplicationRoot` resolves `themeMode` from the cubit state *or* the stored pref. On first run `SharedPrefs.getIsAppFirstRun()` seeds the pref to device default. Theme keys and the `ThemeState` enum live in `core/constants/constants.dart`. Colors/`ThemeData` are defined only in `core/theme/app_colors.dart` and `app_theme.dart`.
- **Routing:** a single static `GoRouter` in `core/utils/app_router.dart`; route paths are `static const` strings on `AppRouter`. `/` currently maps to `OnboardingView`.
- **State management:** `flutter_bloc` cubits. No DI container yet.

## Folder conventions

- `lib/app/` — app root (future home for `di/` and `navigation/`).
- `lib/core/utils/` — router, SharedPrefs and other helpers (not `core/helpers/`).
- `lib/core/shared/layout/` and `lib/core/shared/widgets/` — reusable UI (e.g. `DefaultPadding`, `ThemeSwitcherWidget`).
- Features follow:
  ```
  lib/features/<name>/
    data/{models,repos}
    presentation/{views,widgets,manager}   # cubits go in manager/, beside views/, never inside it
  ```
  Create sub-folders only when they get files.
