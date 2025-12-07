# Onboarding Flow - FlowFit Kids

## ⚠️ DEPRECATED: Adult Survey Flow

The adult survey flow (Steps 0-4) has been replaced with the **Whale-Themed Buddy Onboarding** for kids aged 7-12.

### Old Survey Steps (REMOVED - Adult-focused, not kid-friendly)

❌ **Survey Intro** - Welcome screen with features
❌ **Basic Info** - Age (13-120), Gender (not inclusive)
❌ **Body Measurements** - Height, Weight (triggers body image issues)
❌ **Activity Goals** - Too complex for kids
❌ **Daily Targets** - Calorie/macro tracking (harmful for children)

**Reason for Removal**: COPPA compliance, child safety, kid-friendly UX required.

---

## ✅ NEW: Whale-Themed Buddy Onboarding (8 Screens)

**Target Audience**: Kids aged 7-12
**Theme**: Ocean whale companion
**Duration**: ~90 seconds
**COPPA Compliant**: Minimal data collection

### Step 1: Buddy Welcome (`buddy_welcome_screen.dart`)

- **Route**: `/buddy-welcome`
- **Purpose**: First impression with animated whale buddy
- **Features**:
  - Animated bouncing whale (Ocean Blue #4ECDC4)
  - "Meet Your Fitness Buddy!" heading
  - "Your new whale companion..." subtitle
  - Large "LET'S GO!" button
- **Navigation**: → `/buddy-intro`

### Step 2: Buddy Intro (`buddy_intro_screen.dart`)

- **Route**: `/buddy-intro`
- **Purpose**: Whale asks for user's name (conversational)
- **Speech Bubble**: "Splash splash, thanks for finding me. If my name is Bubbles, what's your name?"
- **Input**: "Name for Bubbles' friend..."
- **Features**:
  - Auto-focus text field
  - Skip button (top-right)
  - Disabled next until input
- **Backend**: `setUserName(name)` → state
- **Navigation**: → `/buddy-hatch`

### Step 3: Buddy Hatch (`buddy_hatch_screen.dart`)

- **Route**: `/buddy-hatch`
- **Purpose**: Celebration micro-interaction
- **Message**: "You found a baby whale! 🐋"
- **Animation**: Scale + fade with elastic curve
- **Duration**: Auto-advance after 2 seconds
- **Navigation**: → `/buddy-color-selection`

### Step 4: Color Selection (`buddy_color_selection_screen.dart`)

- **Route**: `/buddy-color-selection`
- **Purpose**: Choose whale color from 8 options
- **Title**: "Choose your Whale Color!"
- **Subtitle**: "Whales are gentle, playful, and smart..."
- **Colors**: Blue, Teal, Green, Purple, Yellow, Orange, Pink, Gray
- **Layout**: Circular egg pattern around central whale
- **Backend**: `selectColor(color)` → state
- **Navigation**: → `/buddy-naming`

### Step 5: Buddy Naming (`buddy_naming_screen.dart`)

- **Route**: `/buddy-naming`
- **Purpose**: Name the whale buddy
- **Title**: "What do you want to name your baby whale?"
- **Subtitle**: "You can change this later."
- **Name Suggestions** (15 whale-themed):
  - Bubbles, Splash, Wave, Marina, Ocean
  - Finn, Luna, Neptune, Coral, Pearl
  - Moby, Tide, Azure, Blue, Aqua
- **Features**:
  - Shuffle button
  - Validation: 2-20 characters
- **Backend**: `setBuddyName(name)` → state
- **Navigation**: → `/goal-selection`

### Step 6: Goal Selection (`goal_selection_screen.dart`) 🆕

- **Route**: `/goal-selection`
- **Purpose**: Select wellness goals (multi-select)
- **Title**: "What areas would you like support with?"
- **Progress**: ●●●●●●○○ (step 6 of 8)
- **Goals** (5 cards with emojis):
  - 🎯 Boost focus and productivity
  - 🪥 Stay fresh and clean
  - 👟 Be more active
  - 🏔️ Manage stress and anxiety
  - ☎️ Strengthen social skills
- **Features**:
  - Multi-select cards
  - Green checkmark (selected) / Gray plus (unselected)
  - Buddy with lightbulb 💡
- **Backend**: `toggleGoal(goalId)` → state
- **Navigation**: → `/notification-permission`

### Step 7: Notification Permission (`notification_permission_screen.dart`) 🆕

- **Route**: `/notification-permission`
- **Purpose**: Request notification permission (optional)
- **Title**: "Get reminders from {BuddyName}"
- **Preview Card**:
  - "From Bubbles • now"
  - "Remember to drink water! 💧"
- **Buttons**:
  - "TURN ON NOTIFICATIONS" (green)
  - "Maybe later" (gray, outline)
- **Backend**: `setNotificationPermission(granted)` → state
- **Permission**: Uses `permission_handler` package
- **Navigation**: → `/buddy-ready`

### Step 8: Buddy Ready (`buddy_ready_screen.dart`) 🆕

- **Route**: `/buddy-ready`
- **Purpose**: Celebration & completion
- **Speech Bubble**:
  - "Wow! When you take care of yourself,"
  - "you take care of me too!"
  - "Let's swim together! 🌊"
- **Stat Gain**: "😍 Bubbles gained +5.9 Compassion"
- **Features**:
  - Buddy holding heart ❤️
  - Gradient stat card with animation
  - "START ADVENTURE!" button
- **Backend**: `completeOnboarding(userId)` → Supabase
- **Navigation**: → `/dashboard`

---

## Backend Integration (Riverpod)

All screens use `buddyOnboardingProvider` for state management:

```dart
// Set user name (step 2)
ref.read(buddyOnboardingProvider.notifier).setUserName(name);

// Select color (step 4)
ref.read(buddyOnboardingProvider.notifier).selectColor('blue');

// Set buddy name (step 5)
ref.read(buddyOnboardingProvider.notifier).setBuddyName('Bubbles');

// Toggle goal (step 6)
ref.read(buddyOnboardingProvider.notifier).toggleGoal('focus');

// Set notification permission (step 7)
ref.read(buddyOnboardingProvider.notifier).setNotificationPermission(true);

// Complete onboarding (step 8)
await ref.read(buddyOnboardingProvider.notifier).completeOnboarding(userId);

// Access state
final state = ref.watch(buddyOnboardingProvider);
final progress = state.progress; // 0.0 to 1.0
final currentStep = state.currentStep; // 0-7
```

## State Model (`BuddyOnboardingState`)

```dart
class BuddyOnboardingState {
  final int currentStep;              // 0-7
  final String? userName;             // Step 2
  final String? selectedColor;        // Step 4 (default: 'blue')
  final String? buddyName;            // Step 5
  final String? userNickname;         // Optional
  final int? userAge;                 // Optional (7-12)
  final List<String> selectedGoals;   // Step 6
  final bool notificationsGranted;    // Step 7
  final bool isComplete;              // After step 8

  double get progress => (currentStep + 1) / 8;
}
```

## Navigation Flow

```
/survey_intro (Step 0)
    ↓
/survey_basic_info (Step 1)
    ↓
/survey_body_measurements (Step 2)
    ↓
/survey_activity_goals (Step 3)
    ↓
/survey_daily_targets (Step 4)
    ↓
/onboarding1 or /dashboard
```

## Design Consistency

All screens follow the same design pattern:

- ✅ Custom colors (#314158 for text, #01060C for black, #F2F7FD for white)
- ✅ Reusable AppBar with back button
- ✅ Progress indicator showing current step
- ✅ Consistent button styling
- ✅ Form validation
- ✅ Error handling with SnackBars
- ✅ Disabled state for Continue button

## Files Removed

The following duplicate files were removed (2024-11-27):

- ❌ `survey_screen_1.dart` (replaced by `survey_basic_info_screen.dart`)
- ❌ `survey_screen_2.dart` (replaced by `survey_body_measurements_screen.dart`)
- ❌ `survey_screen_3.dart` (replaced by `survey_activity_goals_screen.dart`)

These files had no backend integration and were standalone implementations.
