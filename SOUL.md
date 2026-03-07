# Pacebeats Flutter — Complete Structure & Migration Plan

> Date: March 7, 2026 | Branch: `feat/run`  
> Purpose: Document the full current app architecture so the entire codebase — flows, design system, API keys, env config, native platform setup — can be transplanted into a fresh working Flutter application.

---

## Table of Contents

1. [Tech Stack Overview](#1-tech-stack-overview)
2. [Folder Structure](#2-folder-structure)
3. [Feature Modules](#3-feature-modules)
4. [Core Layer](#4-core-layer)
5. [Design System & Theme](#5-design-system--theme)
6. [State Management](#6-state-management-riverpod)
7. [Navigation](#7-navigation-gorouter)
8. [API Keys & Environment Config](#8-api-keys--environment-config)
9. [Android Native Setup](#9-android-native-setup)
10. [All Dependencies](#10-all-dependencies-pubspecyaml)
11. [Migration Plan — Step by Step](#11-migration-plan--step-by-step)

---

## 1. Tech Stack Overview

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK `^3.10.7`) |
| State management | `flutter_riverpod ^2.6.1` |
| Navigation | `go_router ^14.6.2` |
| Backend / Auth / DB | `supabase_flutter ^2.8.4` |
| GPS | `geolocator ^13.0.2` |
| Step counter | `pedometer ^4.0.2` |
| Local storage | `shared_preferences ^2.3.3` |
| Charts | `fl_chart ^0.69.0` |
| Fonts | `google_fonts ^6.3.2` |
| Notifications | `flutter_local_notifications ^18.0.1` |
| Home widget | `home_widget ^0.7.0` |
| Images | `cached_network_image ^3.4.1`, `image_picker ^1.2.1` |
| Share | `share_plus ^7.0.0` |
| Utilities | `uuid ^4.5.1`, `intl ^0.19.0`, `path_provider ^2.1.5` |

---

## 2. Folder Structure

```
pacebeats_flutter/
├── lib/
│   ├── main.dart                         ← App entry point
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart           ← Supabase URL/key + validation
│   │   ├── error/
│   │   │   └── failures.dart
│   │   ├── router/
│   │   │   └── app_router.dart           ← GoRouter config + all routes
│   │   ├── services/
│   │   │   ├── bluetooth_service.dart
│   │   │   ├── home_widget_service.dart
│   │   │   └── social_notification_service.dart
│   │   ├── theme/
│   │   │   ├── activity_theme.dart       ← Run flow design tokens
│   │   │   ├── analytics_theme.dart
│   │   │   ├── app_colors.dart           ← Global colour palette
│   │   │   ├── app_skin.dart             ← AppSkin enum (skin switcher)
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_theme.dart            ← MaterialTheme factory
│   │   │   ├── app_typography.dart
│   │   │   ├── gamification_theme.dart
│   │   │   ├── login_theme.dart
│   │   │   ├── notification_theme.dart
│   │   │   ├── register_theme.dart
│   │   │   ├── social_theme.dart
│   │   │   └── watch_theme.dart
│   │   ├── utils/
│   │   │   ├── result.dart
│   │   │   └── string_ext.dart
│   │   └── widgets/
│   │       ├── app_error_boundary.dart
│   │       ├── empty_state.dart
│   │       ├── empty_state_view.dart
│   │       ├── glass_card.dart
│   │       ├── gradient_button.dart
│   │       ├── profile_avatar.dart
│   │       ├── shimmer_loading.dart
│   │       └── widgets.dart              ← Barrel export
│   └── features/
│       ├── analytics/
│       ├── auth/
│       ├── gamification/
│       ├── home/
│       ├── music_library/
│       ├── notification/
│       ├── profile/
│       ├── running/
│       ├── shell/
│       ├── social/
│       └── watch/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/pacebeats/pacebeats_flutter/
│       │   ├── MainActivity.kt
│       │   └── PacebeatsSocialWidget.kt  ← Android home widget
│       └── res/
│           ├── layout/social_widget_layout.xml
│           └── xml/social_widget_info.xml
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 3. Feature Modules

Every feature follows **Clean Architecture**: `data` → `domain` → `presentation`.

### 3.1 `auth`
```
auth/
  data/
    datasources/auth_remote_datasource.dart   ← Supabase Auth calls
    models/user_dto.dart
    repositories/auth_repository_impl.dart
  domain/
    entities/user_profile.dart
    repositories/auth_repository.dart
    usecases/
      forgot_password_use_case.dart
      login_use_case.dart
      logout_use_case.dart
      register_use_case.dart
      update_password_use_case.dart
  presentation/
    providers/
      auth_provider.dart                      ← authStateProvider, currentUserProvider
      password_recovery_provider.dart
    screens/
      splash_screen.dart
      login_screen.dart
      register_screen.dart
      forgot_password_screen.dart
      reset_password_screen.dart
```

Auth flow: `splash → login → home` (auto-redirect via GoRouter `redirect`).  
Deep-link scheme: `pacebeats://auth/reset-password`

---

### 3.2 `running` ← _Core feature_
```
running/
  data/
    models/session_dto.dart
    repositories/session_repository_impl.dart  ← Supabase insert
  domain/
    entities/
      running_metrics.dart                      ← pace, distance, HR, cadence, steps
      session_extras.dart                       ← SplitData, LapData, MusicSource
      workout_session.dart                      ← final persisted entity
    repositories/session_repository.dart
    usecases/
      calculate_pace_use_case.dart
      save_session_use_case.dart
  presentation/
    providers/
      running_session_provider.dart             ← StateNotifier (full run state machine)
    screens/
      run_setup_screen.dart                     ← /run-setup
      running_session_screen.dart               ← /running
      post_run_screen.dart                      ← /post-run
```

---

### 3.3 `analytics`
```
analytics/
  data/repositories/analytics_repository_impl.dart   ← Supabase query
  domain/
    repositories/analytics_repository.dart
    usecases/get_sessions_use_case.dart
  presentation/
    providers/analytics_provider.dart
    screens/
      analytics_screen.dart                          ← /stats
      session_detail_screen.dart                     ← /session/:id
```

---

### 3.4 `home`
```
home/
  data/gamification_mock_data.dart
  presentation/
    screens/home_screen.dart                         ← /home
    widgets/
      progress_challenge_cards.dart
      pulse_creature_widget.dart
      world_widget.dart
```

---

### 3.5 `gamification`
```
gamification/
  data/mock/gamification_mock_data.dart
  domain/models/
    beat.dart
    pulse_creature.dart
    streak.dart
    world_zone.dart
  presentation/
    providers/
      beats_provider.dart
      creature_provider.dart
      streak_provider.dart
      world_provider.dart
    screens/
      creature_detail_screen.dart                    ← /creature
      evolution_cutscene_screen.dart                 ← /evolution
      streak_view_screen.dart                        ← /streak
    widgets/
      beat_counter_widget.dart
      creature_widget.dart                           ← animated, HR-synced
      particle_painter.dart
      streak_ring_widget.dart
      world_zone_painter.dart
      zone_popup_card.dart
      creature_painters/
        echo_painter.dart
        flicker_painter.dart
        pulse_painter.dart
        surge_painter.dart
```

---

### 3.6 `music_library`
```
music_library/
  data/
    mock/music_library_mock_data.dart
    repositories/
      local_music_library_repository.dart
      music_library_repository.dart
  domain/
    entities/
      music_folder.dart
      music_track.dart
      playlist.dart
      song_analysis.dart
    models/
      library_tab.dart                              ← LibraryTab enum (spotify, local)
      music_library_snapshot.dart
    repositories/music_library_repository.dart
  presentation/
    providers/
      music_library_provider.dart
      music_library_providers.dart
    screens/
      music_library_screen.dart                     ← /library
      music_song_detail_screen.dart                 ← /library/song/:id
    theme/music_library_theme.dart
```

Routes: `/library`, `/library/spotify`, `/library/local`, `/library/song/:id`

---

### 3.7 `notification`
```
notification/
  data/
    mock/notification_mock_data.dart
    repositories/local_notification_repository.dart
    services/
      android_notification_service.dart
      mock_notification_trigger.dart
  domain/
    entities/notification_models.dart
    repositories/notification_repository.dart
  presentation/
    providers/notification_providers.dart           ← unreadCountProvider
    screens/notification_center_sheet.dart          ← bottom sheet
    widgets/
      notification_empty_state.dart
      notification_tile.dart
```

---

### 3.8 `profile`
```
profile/
  data/
    models/
      onboarding_survey_models.dart
      profile_models.dart
      profile_settings_models.dart
    repositories/local_profile_settings_repository.dart
    services/
      avatar_storage_service.dart                   ← Supabase Storage
      profile_local_storage_service.dart
  domain/repositories/profile_settings_repository.dart
  presentation/
    providers/
      profile_providers.dart
      skin_provider.dart                            ← theme skin switcher
    routes/profile_routes.dart
    screens/
      about_us_screen.dart                          ← /about-us
      legal_screen.dart                             ← /terms, /privacy
      onboarding_survey_screen.dart                 ← /onboarding-survey
      profile_screen.dart                           ← /profile
      settings_screen.dart                          ← /settings
    theme/profile_theme_tokens.dart
    widgets/profile_ui_sections.dart
  profile.dart                                      ← barrel export
```

---

### 3.9 `social`
```
social/
  data/
    models/social_models.dart
    repositories/
      local_social_repository.dart
      social_repository.dart
    services/
      social_local_storage_service.dart
      social_share_service.dart                     ← share_plus wrapper
    social_mock_data.dart
  domain/
    entities/social_entities.dart
    repositories/social_repository.dart
  presentation/
    providers/
      social_controller.dart
      social_provider.dart
    screens/social_screen.dart                      ← /social
    widgets/
      boards_tab.dart
      challenges_tab.dart
      crew_tab.dart
      feed_tab.dart
      shareable_profile_card.dart
      social_activity_card.dart
```

---

### 3.10 `watch`
```
watch/
  domain/entities/watch_models.dart
  presentation/
    providers/watch_providers.dart                  ← watchConnectionProvider, hrStreamProvider
    screens/
      watch_data_screen.dart                        ← /watch-data
      watch_face_screen.dart                        ← /watch
```

---

### 3.11 `shell`
```
shell/
  main_shell.dart    ← ShellRoute wrapper: top app bar + bottom nav (5 items)
```

Bottom nav items: Home · Social · **▶ Run** (pushes `/run-setup`) · Stats · Profile

---

## 4. Core Layer

### `lib/main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorBoundary.init();
  AppConfig.validate();              // validates URL/key match

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: PacebeatsApp()));
}
```

`PacebeatsApp` is a `ConsumerStatefulWidget`. It listens to `Supabase.instance.client.auth.onAuthStateChange` to drive `passwordRecoveryProvider` and cleans up on `signedOut`.

---

## 5. Design System & Theme

### Theme entry point: `lib/core/theme/app_theme.dart`
- Builds a `ThemeData` (light or dark) from `AppSkin`.
- Used in `MaterialApp.router(theme: ...)`.

### `AppSkin` (`app_skin.dart`)
- Enum with multiple skin variants; chosen via `skinProvider` (Riverpod).
- Persisted to `shared_preferences`.

### `AppColors` (`app_colors.dart`)
- Central colour constants referenced by all sub-themes.

### Per-feature theme files
Each major feature has its own theme data class accessed via `Theme.of(context).extension<...>()` or static factory:

| File | Used by |
|---|---|
| `activity_theme.dart` | Run setup, running session, post-run |
| `analytics_theme.dart` | Stats / session detail |
| `gamification_theme.dart` | Creature, beats, world |
| `login_theme.dart` | Login screen |
| `register_theme.dart` | Register screen |
| `notification_theme.dart` | Notification sheet |
| `social_theme.dart` | Social screen |
| `watch_theme.dart` | Watch screens |
| `music_library_theme.dart` | Music library |
| `profile_theme_tokens.dart` | Profile & settings |

### `AppTypography` (`app_typography.dart`)
- Google Fonts (Jakarta Sans family) text styles used throughout.

### Shared widgets (`lib/core/widgets/`)
| Widget | Purpose |
|---|---|
| `GlassCard` | Frosted glass card container |
| `GradientButton` | Primary CTA with gradient fill |
| `ProfileAvatar` | Cached avatar with fallback initials |
| `ShimmerLoading` | Skeleton loader placeholder |
| `EmptyState` / `EmptyStateView` | Zero-content states |
| `AppErrorBoundary` | Global uncaught exception handler |

---

## 6. State Management (Riverpod)

All providers use `flutter_riverpod`. The app wraps `main()` in `ProviderScope`.

### Key providers

| Provider | File | Type | Responsibility |
|---|---|---|---|
| `authStateProvider` | `auth_provider.dart` | `StreamProvider` | Supabase auth stream → `UserProfile?` |
| `currentUserProvider` | `auth_provider.dart` | `Provider` | Current `UserProfile` |
| `passwordRecoveryProvider` | `password_recovery_provider.dart` | `StateNotifier` | Password reset deeplink state |
| `runningSessionProvider` | `running_session_provider.dart` | `StateNotifier` | Full run state machine |
| `watchConnectionProvider` | `watch_providers.dart` | `StateProvider` | BT connection status |
| `hrStreamProvider` | `watch_providers.dart` | `StreamProvider` | Heart rate BPM stream |
| `creatureProvider` | `creature_provider.dart` | `StateNotifier` | Gamification creature |
| `worldZonesProvider` | `world_provider.dart` | `StateNotifier` | World zones |
| `beatsProvider` | `beats_provider.dart` | `StateNotifier` | Beat currency balance |
| `streakProvider` | `streak_provider.dart` | `StateNotifier` | Streak counter |
| `skinProvider` | `skin_provider.dart` | `StateNotifier` | Active app skin/theme |
| `unreadCountProvider` | `notification_providers.dart` | `Provider` | Notification badge count |
| `analyticsProvider` | `analytics_provider.dart` | `FutureProvider` | Past sessions list |
| `musicLibraryProvider` | `music_library_providers.dart` | `StateNotifier` | Music library snapshot |
| `socialProvider` | `social_provider.dart` | `StateNotifier` | Social feed state |

---

## 7. Navigation (GoRouter)

### Route table

| Route | Screen | Inside Shell? |
|---|---|---|
| `/splash` | `SplashScreen` | No |
| `/login` | `LoginScreen` | No |
| `/register` | `RegisterScreen` | No |
| `/forgot-password` | `ForgotPasswordScreen` | No |
| `/reset-password` | `ResetPasswordScreen` | No |
| `/home` | `HomeScreen` | **Yes** |
| `/social` | `SocialScreen` | **Yes** |
| `/stats` | `AnalyticsScreen` | **Yes** |
| `/profile` | `ProfileScreen` | **Yes** |
| `/run-setup` | `RunSetupScreen` | No |
| `/running` | `RunningSessionScreen` | No |
| `/post-run` | `PostRunScreen` | No |
| `/session/:id` | `SessionDetailScreen` | No |
| `/library` | `MusicLibraryPage` | No |
| `/library/spotify` | `MusicLibraryPage(tab=spotify)` | No |
| `/library/local` | `MusicLibraryPage(tab=local)` | No |
| `/library/song/:id` | `MusicSongDetailScreen` | No |
| `/settings` | `SettingsScreen` | No |
| `/about-us` | `AboutUsScreen` | No |
| `/terms` | `LegalScreen(terms)` | No |
| `/privacy` | `LegalScreen(privacy)` | No |
| `/onboarding-survey` | `OnboardingSurveyScreen` | No |
| `/watch` | `WatchFaceScreen` | No |
| `/watch-data` | `WatchDataScreen` | No |
| `/creature` | `CreatureDetailScreen` | No |
| `/evolution` | `EvolutionCutsceneScreen` | No |
| `/streak` | `StreakViewScreen` | No |

### Auth redirect logic (in `routerProvider`)
```
loading         → no redirect
recovery active → /reset-password (force)
logged out      → /login
logged in + auth route → /home
```

### Deep-link scheme
```
pacebeats://auth/reset-password
```
(registered in `AndroidManifest.xml` intent-filter + `AppConfig.authRedirectScheme`)

---

## 8. API Keys & Environment Config

### File: `lib/core/config/app_config.dart`

```dart
// Supabase project — dev fallback (hardcoded, overridable at build time)
static const _devUrl  = 'https://mxhnswymqijymrwvsybm.supabase.co';
static const _devKey  = '<anon-jwt>';

// Build-time overrides via --dart-define
static const _urlPrimary  = String.fromEnvironment('SUPABASE_URL');
static const _anonPrimary = String.fromEnvironment('SUPABASE_ANON_KEY');
// Also accepts: SUPABASE_PROJECT_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_KEY
```

### How to pass new keys at build time
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<YOUR_PROJECT>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Validation
`AppConfig.validate()` is called in `main()`. It:
1. Checks URL and key are non-empty.
2. Parses the project ref out of the URL hostname.
3. Decodes the JWT and extracts `ref` from the payload.
4. Throws `StateError` if they don't match (prevents silent misconfiguration).

### What needs updating in a new project
- Replace `_devUrl` and `_devKey` with the new Supabase project URL and anon key.
- Update `authRedirectScheme` / `authRedirectHost` if the deep-link scheme changes.
- Update `AndroidManifest.xml` intent-filter `android:scheme` and `android:host`.

---

## 9. Android Native Setup

### Package ID
`com.pacebeats.pacebeats_flutter`

### Permissions (`AndroidManifest.xml`)
```xml
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
POST_NOTIFICATIONS
FOREGROUND_SERVICE
FOREGROUND_SERVICE_LOCATION
ACTIVITY_RECOGNITION
com.google.android.gms.permission.ACTIVITY_RECOGNITION
BLUETOOTH (≤ API 30)
BLUETOOTH_ADMIN (≤ API 30)
BLUETOOTH_CONNECT
BLUETOOTH_SCAN
```

### Deep-link intent filter
```xml
<intent-filter android:autoVerify="true">
  <data android:scheme="pacebeats" android:host="auth"/>
</intent-filter>
```

### Native Kotlin files
| File | Purpose |
|---|---|
| `MainActivity.kt` | Default Flutter activity |
| `PacebeatsSocialWidget.kt` | Android App Widget (home screen) |

### Android App Widget resources
```
res/layout/social_widget_layout.xml
res/drawable/social_widget_bg.xml
res/xml/social_widget_info.xml
```

### Build config (`android/app/build.gradle.kts`)
- Kotlin DSL; check `compileSdk`, `minSdk`, `targetSdk` and `applicationId` (`com.pacebeats.pacebeats_flutter`).

---

## 10. All Dependencies (`pubspec.yaml`)

```yaml
name: pacebeats_flutter
version: 1.0.0+1

environment:
  sdk: ^3.10.7

dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  supabase_flutter: ^2.8.4
  geolocator: ^13.0.2
  pedometer: ^4.0.2
  shared_preferences: ^2.3.3
  fl_chart: ^0.69.0
  google_fonts: ^6.3.2
  intl: ^0.19.0
  uuid: ^4.5.1
  cupertino_icons: ^1.0.8
  image_picker: ^1.2.1
  path_provider: ^2.1.5
  cached_network_image: ^3.4.1
  share_plus: ^7.0.0
  flutter_local_notifications: ^18.0.1
  home_widget: ^0.7.0

dev_dependencies:
  flutter_lints: ^6.0.0
```

---

## 11. Migration Plan — Step by Step

This plan covers transplanting the entire codebase into a new clean Flutter project.

---

### Phase 1 — Bootstrap the new project

```bash
flutter create <new_app_name> \
  --org com.<yourcompany> \
  --platforms android,ios
cd <new_app_name>
```

**What to change immediately:**
- `pubspec.yaml` → copy all `dependencies` and `dev_dependencies` from above.
- `pubspec.yaml` → set `name:`, `description:`, `version:`.
- Run `flutter pub get`.

---

### Phase 2 — Copy `lib/` (complete)

Copy the full `lib/` directory from `pacebeats_flutter` into the new project.

```bash
cp -r pacebeats_flutter/lib/* <new_app_name>/lib/
```

**Files that need edits after copy:**

| File | What to change |
|---|---|
| `lib/core/config/app_config.dart` | Replace `_devUrl` and `_devKey` with new Supabase project credentials |
| `lib/core/config/app_config.dart` | Update `authRedirectScheme` / `authRedirectHost` if renaming the deep-link |
| `lib/main.dart` | Usually no changes needed; verify `AppConfig.validate()` passes |

---

### Phase 3 — Update Supabase credentials

1. Create (or reuse) a Supabase project at [supabase.com](https://supabase.com).
2. Copy **Project URL** and **anon public key** from Settings → API.
3. In `app_config.dart`:
   ```dart
   static const _devUrl  = 'https://<NEW_PROJECT_REF>.supabase.co';
   static const _devKey  = 'eyJ...new-anon-key...';
   ```
4. Or pass at build time (preferred for production):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
5. Verify `AppConfig.validate()` passes (throws if URL/key project refs mismatch).

---

### Phase 4 — Android native setup

**4a. Package ID**
- `android/app/build.gradle.kts` → change `applicationId` to your new package (e.g. `com.yourcompany.newapp`).
- `android/app/src/main/kotlin/` → rename the directory structure to match the new package.
- `android/settings.gradle.kts` → update `rootProject.name`.

**4b. Copy Kotlin files**
- Copy `MainActivity.kt` from `com.pacebeats.pacebeats_flutter` to the new package path.
- Update the `package` declaration at the top: `package com.<yourcompany>.<newapp>`.
- Copy `PacebeatsSocialWidget.kt` (same package rename).

**4c. AndroidManifest.xml**
- Copy all `<uses-permission>` entries (see Section 9).
- Update `android:scheme` and `android:host` in the auth deep-link intent filter if changing the scheme name.
- Update the `<receiver>` block for `PacebeatsSocialWidget` if keeping the home widget.

**4d. Android App Widget resources**
- Copy from `android/app/src/main/res/`:
  - `layout/social_widget_layout.xml`
  - `drawable/social_widget_bg.xml`
  - `xml/social_widget_info.xml`

**4e. App icon**
- Replace `res/mipmap-*/ic_launcher.png` with the new icon assets.
- Update `launch_background.xml` and `styles.xml` for splash colour.

---

### Phase 5 — iOS native setup (if needed)

- Update `ios/Runner/Info.plist`:
  - Add URL scheme for deep-link: `pacebeats` (or your new scheme).
  - Add permissions for location (`NSLocationWhenInUseUsageDescription`), activity recognition, Bluetooth.
- Update bundle ID in Xcode: `Signing & Capabilities`.
- `geolocator`, `pedometer`, and `flutter_local_notifications` each require `Info.plist` entries — see their respective pub.dev documentation.

---

### Phase 6 — Supabase database schema

The following tables are referenced by repository implementations:

| Table | Used by |
|---|---|
| `profiles` | `auth_remote_datasource.dart`, `profile` feature |
| `sessions` | `session_repository_impl.dart` — run save |
| `session_splits` | split data per km |
| `session_songs` | music played during run |
| `notifications` | `local_notification_repository.dart` |
| `social_posts` / `crews` / `challenges` | `local_social_repository.dart` |

**Action:** Re-run the SQL schema scripts (from `docs/fix-admin-dashboard-rls-policies.sql` and `docs/fix-realtime-and-hr-issues.sql`) against the new Supabase project.

Set up Row Level Security (RLS) policies — see `docs/fix-admin-dashboard-rls-policies.sql` for the existing policy definitions.

Enable Realtime on tables that use `supabase.from(...).stream(...)`.

---

### Phase 7 — Supabase Storage

`avatar_storage_service.dart` uploads profile avatars to a Supabase Storage bucket named `avatars`.

In the new Supabase project:
1. Create bucket `avatars` (public or with RLS policy for authenticated users).
2. No code changes needed; bucket name is referenced as a string constant.

---

### Phase 8 — Feature flags / mock vs real data

Several features are currently using mock/local data. After migration these need to be wired to real backends:

| Feature | Current state | Action needed |
|---|---|---|
| Watch HR (`hrStreamProvider`) | Returns static 72 bpm | Wire to real Bluetooth HR stream |
| Spotify music | "Coming soon" info chip | Implement Spotify OAuth |
| Local music picker | "Coming soon" info chip | Implement file picker |
| Notifications | `mock_notification_trigger.dart` | Wire to real Supabase push/local triggers |
| Social feed | `social_mock_data.dart` | Wire to real Supabase tables |
| Gamification (creature, world, streaks) | `gamification_mock_data.dart` | Wire to Supabase |
| Quick Start last-session load | Hardcoded defaults | Load from Supabase / `shared_preferences` |
| Route map on post-run | Placeholder | Implement MapLibre GPS trace |
| Discard session | Goes to `/home` without deleting | Add Supabase delete call |

---

### Phase 9 — Verify and run

```bash
flutter pub get
flutter analyze
flutter run
```

Expected: `AppConfig.validate()` passes → Supabase initializes → Splash screen → Login screen (if not authenticated).

---

### Migration Checklist

- [ ] New Flutter project created with correct package ID
- [ ] `pubspec.yaml` dependencies copied and `flutter pub get` run
- [ ] `lib/` directory copied
- [ ] `app_config.dart` updated with new Supabase URL and anon key
- [ ] `AppConfig.validate()` passes on first run
- [ ] `AndroidManifest.xml` permissions copied
- [ ] Android package name updated in `build.gradle.kts` and Kotlin files
- [ ] Deep-link intent filter updated
- [ ] iOS `Info.plist` permissions updated (if targeting iOS)
- [ ] Supabase database schema re-applied on new project
- [ ] RLS policies re-applied
- [ ] Realtime enabled on required tables
- [ ] `avatars` storage bucket created
- [ ] App icon and splash assets replaced
- [ ] `flutter analyze` passes with no errors
- [ ] Auth flow works end-to-end (register → login → home)
- [ ] Run flow works end-to-end (setup → running → post-run → save to Supabase)
- [ ] Analytics tab loads past sessions from new DB
