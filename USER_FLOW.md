# Pulsify — User Flow

> Current State: March 2026 — `development` branch  
> This document maps every screen-to-screen transition in the app as it exists today. Update it whenever a new route is added or a navigation call changes.

---

## 1. App Launch & Splash

```
App opened
    └── SplashScreen  (route: '/')
            │  animate logo (1.5 s) + minimum wait (3 s)
            │  initialize Supabase auth session
            │
            ├── session FOUND + email verified + survey COMPLETE
            │       └──▶ /dashboard
            │
            ├── session FOUND + email verified + survey INCOMPLETE
            │       └──▶ /survey_intro
            │
            └── no session / not authenticated
                    └──▶ /welcome
```

---

## 2. Authentication Flow

### 2A — Welcome Screen `/welcome`

```
WelcomeScreen
    ├── "Get Started" (Sign Up)  ──▶ /signup
    └── "Log In"                 ──▶ /login
        │
        │  (also: if already authenticated on this screen)
        └── auto-redirect         ──▶ /dashboard
```

### 2B — Sign Up `/signup`

```
SignUpScreen
    ├── fill name + email + password → tap "Create Account"
    │       │
    │       ├── email already verified
    │       │       └──▶ /survey_intro  (with name, email, userId)
    │       │
    │       └── email NOT yet verified
    │               └──▶ /email_verification  (with name, email, userId)
    │
    └── "Already have an account? Log in"  ──▶ /login
```

### 2C — Email Verification `/email_verification`

```
EmailVerificationScreen
    ├── user taps verification link in email (deep link)
    │       └── email confirmed
    │               └──▶ /survey_intro  (with userId)
    │
    └── "Resend email" button (cooldown timer, re-sends verification email)
```

### 2D — Log In `/login`

```
LoginScreen
    ├── email + password login
    │       ├── success + survey COMPLETE   ──▶ /dashboard
    │       └── success + survey INCOMPLETE ──▶ /survey_intro
    │
    ├── Google / Apple SSO
    │       └── same branch logic as above
    │
    └── "Don't have an account? Sign up"  ──▶ /signup
```

---

## 3. Onboarding / Survey Flow

> Triggered for new users (or users who haven't completed their profile).  
> All steps are pushed sequentially. Completing step 4 commits data and clears the survey from the stack.

```
/survey_intro  (Step 0 — Introduction)
    └── "Let's Start"  ──▶ /survey_basic_info

/survey_basic_info  (Step 1 — Name, age, gender)
    └── "Next"  ──▶ /survey_body_measurements

/survey_body_measurements  (Step 2 — Height, weight)
    └── "Next"  ──▶ /survey_activity_goals

/survey_activity_goals  (Step 3 — Fitness goal, activity level)
    └── "Next"  ──▶ /survey_daily_targets

/survey_daily_targets  (Step 4 — Calorie & step targets)
    └── "Finish"
            ├── saves profile to Supabase
            └── pushNamedAndRemoveUntil ──▶ /dashboard  (clears entire stack)
```

> **Back navigation**: Each step has a back button that pops to the previous step.

---

## 4. Main Dashboard

Route: `/dashboard`  
Auth-guarded — redirects to `/welcome` if session expires mid-use.

The dashboard is a **5-tab bottom-navigation** shell. Switching tabs does not push routes; tabs swap in place via `IndexedStack`.

| Tab index | Label | Screen class |
|---|---|---|
| 0 | Home | `HomeScreen` |
| 1 | Health | `HealthScreen` |
| 2 | Track | `TrackScreen` |
| 3 | Progress | `ProgressScreen` |
| 4 | Profile | `ProfileScreen` |

---

## 5. Home Tab (Tab 0)

```
HomeScreen
    ├── "AI Activity Tracker" card
    │       └──▶ /trackertest  (TFLite stress/calm classifier live view)
    │
    └── "Calming Routes / Mission" card
            └──▶ /mission  (wellness map + GPS route finder)
```

---

## 6. Health Tab (Tab 1)

```
HealthScreen
    ├── Heart rate panel — displays live BPM from watch or phone
    │       └── (no navigation — in-tab display only)
    │
    └── (other health metrics displayed inline — no sub-navigation currently)
```

---

## 7. Track Tab (Tab 2)

```
TrackScreen
    └── "Start Workout" button  ──▶ /workout/select-type

/workout/select-type  —  WorkoutTypeSelectionScreen
    ├── Running                ──▶ /workout/running/setup
    ├── Walking                ──▶ /workout/walking/options
    └── Resistance / Strength  ──▶ /workout/resistance/select-split
```

### 7A — Running Flow

```
/workout/running/setup  —  RunningSetupScreen
    │  choose distance goal, pace target
    └── "Start Run"  ──▶ /workout/running/active

/workout/running/active  —  ActiveRunningScreen
    │  live GPS map + BPM + pace + timer
    ├── "AI Tracker" shortcut  ──▶ /trackertest  (overlay)
    └── "Finish Run"  ──▶ /workout/running/summary

/workout/running/summary  —  RunningSummaryScreen
    ├── "Share Achievement"  ──▶ /workout/running/share  (with session data)
    └── "Done"  ──────────── pushNamedAndRemoveUntil ──▶ /dashboard

/workout/running/share  —  ShareAchievementScreen
    └── share card via OS share sheet → back to summary or dashboard
```

### 7B — Walking Flow

```
/workout/walking/options  —  WalkingOptionsScreen
    ├── "Free Walk"   ──▶ ActiveWalkingScreen  (direct push)
    └── "Mission Walk"──▶ MissionCreationScreen  (direct push)
            │  set distance/step target
            └── "Start"  ──▶ ActiveWalkingScreen

ActiveWalkingScreen
    │  live GPS + step counter + BPM
    └── "Finish"  ──▶ WalkingSummaryScreen

WalkingSummaryScreen
    └── "Done"  ──▶ /dashboard
```

### 7C — Resistance / Strength Flow

```
/workout/resistance/select-split  —  SplitSelectionScreen
    │  choose muscle group split (Push/Pull/Legs, etc.)
    └── "Start"  ──▶ /workout/resistance/active

/workout/resistance/active  —  ActiveResistanceScreen
    │  set / rep tracker per exercise
    └── "Finish"  ──▶ /workout/resistance/summary

/workout/resistance/summary  —  ResistanceSummaryScreen
    └── "Done"  ──▶ /dashboard
```

---

## 8. Progress Tab (Tab 3)

```
ProgressScreen
    └── (charts and history displayed inline — no sub-navigation currently)
```

---

## 9. Profile Tab (Tab 4)

```
ProfileScreen
    ├── ⚙ Settings icon / "Settings" row  ──▶ /settings
    │
    ├── Goals section
    │       ├── Weight Goals     ──▶ /weight-goals
    │       ├── Fitness Goals    ──▶ /fitness-goals
    │       └── Nutrition Goals  ──▶ /nutrition-goals
    │
    ├── Account section
    │       ├── Change Password  ──▶ /change-password
    │       └── Delete Account   ──▶ /delete-account  (confirmation dialog)
    │
    ├── "Edit Profile / Re-do Survey"  ──▶ /survey-intro
    │
    └── Sign Out
            └── confirmation dialog
                    └── confirmed  ──▶ pushNamedAndRemoveUntil ──▶ /welcome
```

### 9A — Settings Screen `/settings`

```
SettingsScreen
    ├── Privacy Policy          ──▶ /privacy-policy
    ├── Notification Settings   ──▶ /notification-settings
    ├── App Integration         ──▶ /app-integration  (Galaxy Watch pairing)
    ├── Language                ──▶ /language-settings
    ├── Units (kg/lbs, km/mi)   ──▶ /unit-settings
    ├── Terms of Service        ──▶ /terms-of-service
    ├── Help & Support          ──▶ /help-support
    └── About Us                ──▶ /about-us
```

---

## 10. Wellness Tracker Flow

Launched from the AI Tracker card on Home Tab or via deep-link `/wellness-tracker`.

```
/wellness-tracker  —  WellnessTrackerPage
    │
    ├── first-time user (no wellness profile)
    │       └── auto-redirect  ──▶ /wellness-onboarding
    │
    ├── ⚙ Settings icon  ──▶ /wellness-settings
    │
    ├── Stress banner appears (AI label = "Stress")
    │       └── "Show Routes"  ──▶ /workout  (calming route finder)
    │
    └── (live BPM + accelerometer + TFLite inference displayed inline)

/wellness-onboarding  —  WellnessOnboardingScreen
    └── "Get Started"  ──▶ /wellness-tracker  (replaces onboarding)
```

---

## 11. AI Activity / Stress Tracker `/trackertest`

Stand-alone `TrackerPage` — accessible from Home Tab "AI Tracker" card and from `ActiveRunningScreen`.

```
TrackerPage
    ├── sensor source selector (Phone accel / Watch / Simulation)
    ├── BPM source selector (Phone camera / Watch / Simulation slider)
    ├── live sliding window (320 samples) fills → TFLite inference runs
    └── result label: Calm / Stress / Cardio / Strength + confidence %
        (no outbound navigation — back button pops to caller)
```

---

## 12. Mission / Calming Routes `/mission`

```
MapsPageWrapper
    └── GPS map + nearby calming walking routes (OpenRouteService API)
        (no outbound navigation — back button pops to Home Tab)
```

---

## 13. Session Expiry / Logout (Global)

Can occur from anywhere in the app.

```
Auth session expires  OR  user signs out manually
    └── any screen listening to authNotifierProvider
            └── pushNamedAndRemoveUntil ──▶ /welcome  (clears entire stack)
```

---

## 14. Deep Links

Handled by `DeepLinkHandler` (Supabase PKCE callback flow).

| Deep link path | Where it lands |
|---|---|
| `Pulsify://auth/callback?...` | Supabase processes token → triggers `authNotifierProvider` → email verified → `/survey_intro` |

---

## Full Route Index

| Route | Screen | Notes |
|---|---|---|
| `/` | `SplashScreen` | Entry point |
| `/loading` | `LoadingScreen` | Unused splash variant (goes to `/welcome`) |
| `/welcome` | `WelcomeScreen` | Auth gateway |
| `/login` | `LoginScreen` | Email/password + SSO |
| `/signup` | `SignUpScreen` | New account creation |
| `/email_verification` | `EmailVerificationScreen` | Post-signup gate |
| `/survey_intro` | `SurveyIntroScreen` | Onboarding step 0 |
| `/survey_basic_info` | `SurveyBasicInfoScreen` | Onboarding step 1 |
| `/survey_body_measurements` | `SurveyBodyMeasurementsScreen` | Onboarding step 2 |
| `/survey_activity_goals` | `SurveyActivityGoalsScreen` | Onboarding step 3 |
| `/survey_daily_targets` | `SurveyDailyTargetsScreen` | Onboarding step 4 (final) |
| `/dashboard` | `DashboardScreen` | 5-tab main shell |
| `/trackertest` | `TrackerPage` | AI stress/calm classifier |
| `/mission` | `MapsPageWrapper` | Calming route map |
| `/phone_heart_rate` | `PhoneHeartRateScreen` | Watch HR on phone |
| `/wellness-tracker` | `WellnessTrackerPage` | Wellness + stress view |
| `/wellness-onboarding` | `WellnessOnboardingScreen` | First-time wellness setup |
| `/wellness-settings` | `WellnessSettingsScreen` | Wellness config |
| `/workout/select-type` | `WorkoutTypeSelectionScreen` | Workout entry |
| `/workout/running/setup` | `RunningSetupScreen` | Run config |
| `/workout/running/active` | `ActiveRunningScreen` | Live run |
| `/workout/running/summary` | `RunningSummaryScreen` | Post-run |
| `/workout/running/share` | `ShareAchievementScreen` | Share card |
| `/workout/walking/options` | `WalkingOptionsScreen` | Walk mode select |
| `/workout/resistance/select-split` | `SplitSelectionScreen` | Gym split select |
| `/workout/resistance/active` | `ActiveResistanceScreen` | Live resistance |
| `/workout/resistance/summary` | `ResistanceSummaryScreen` | Post-resistance |
| `/settings` | `SettingsScreen` | App settings |
| `/privacy-policy` | `PrivacyPolicyScreen` | |
| `/notification-settings` | `NotificationSettingsScreen` | |
| `/app-integration` | `AppIntegrationScreen` | Watch pairing |
| `/language-settings` | `LanguageSettingsScreen` | |
| `/unit-settings` | `UnitSettingsScreen` | kg/lbs toggle |
| `/terms-of-service` | `TermsOfServiceScreen` | |
| `/help-support` | `HelpSupportScreen` | |
| `/about-us` | `AboutUsScreen` | |
| `/change-password` | `ChangePasswordScreen` | |
| `/delete-account` | `DeleteAccountScreen` | |
| `/weight-goals` | `WeightGoalsScreen` | |
| `/fitness-goals` | `FitnessGoalsScreen` | |
| `/nutrition-goals` | `NutritionGoalsScreen` | |
| `/font-demo` | `FontDemoScreen` | Dev only |
