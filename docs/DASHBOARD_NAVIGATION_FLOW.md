# FlowFit Dashboard & Navigation Flow Documentation

## Overview
This document outlines the current user flow, UI structure, and styling for the FlowFit main dashboard and navigation system. Use this to identify areas for improvement and enhancement.

---

## 🎯 User Flow Journey

### 1. App Launch Flow
```
LoadingScreen (3s) → WelcomeScreen → SignUp/Login → Onboarding → DashboardScreen
```

#### LoadingScreen
- **Duration**: 3 seconds
- **Purpose**: Brand introduction and initialization
- **Visual Elements**:
  - Gradient background (Primary Blue → Light Blue)
  - Animated logo (Heart Pulse icon in white circle)
  - App name "FlowFit" with tagline
  - Loading spinner with "Initializing..." text
  - Footer: "Connect your Galaxy Watch"
- **Animations**: Fade-in and scale animations (1.5s duration)
- **Auto-navigates to**: `/welcome`

#### WelcomeScreen
- **Purpose**: First-time user introduction
- **Visual Elements**:
  - Full-screen gradient (Blue → Light Blue → Cyan)
  - Logo with heart pulse icon
  - App name and tagline: "Your Heart, Your Health"
  - Description text
  - Two CTAs: "Get Started" (white button) and "I Already Have an Account" (outlined)
  - Footer: "Compatible with Galaxy Watch"
- **Navigation Options**:
  - "Get Started" → `/signup`
  - "I Already Have an Account" → `/trackertest` (currently bypasses login)

#### OnboardingScreen
- **Type**: PageView with 3 slides
- **Pages**:
  1. Track Your Heart Rate (Blue)
  2. Personalized Workouts (Cyan)
  3. Track Your Progress (Light Blue)
- **Features**:
  - Skip button (top-right)
  - Page indicators (dots)
  - Next/Get Started button
- **Final destination**: `/dashboard`

---

## 📱 Main Dashboard Structure

### DashboardScreen (Bottom Navigation)
The main hub with 5 tabs using bottom navigation bar.

#### Bottom Navigation Bar
- **Type**: Fixed bottom navigation (5 items)
- **Style**:
  - Background: White
  - Selected color: Primary Blue (#3B82F6)
  - Unselected color: Grey 400
  - Elevation: 0 (with custom shadow)
  - Font size: 12px
  - Icons: Solar Icons (Outline/Bold variants)

#### Navigation Items:
1. **Home** - `SolarIcons.home`
2. **Activity** - `SolarIcons.heartPulse`
3. **Track** - `SolarIcons.target`
4. **Progress** - `SolarIcons.chartSquare`
5. **Profile** - `SolarIcons.user`

---

## 🏠 Home Tab (Primary Screen)

### Layout Structure
```
SafeArea
└── SingleChildScrollView
    └── Padding (20px)
        ├── Header Section
        ├── Stats Cards (2-column grid)
        ├── Streak Card
        └── Quick Track Grid (2x3)
```

### 1. Header Section
- **Greeting**: "Good Morning, Jim!"
- **Subtitle**: "Let's make today a great day."
- **Action**: Bell notification icon (top-right)
- **Style**: 
  - Greeting: headlineSmall, bold, black
  - Subtitle: bodyMedium, grey 600

### 2. Stats Cards Row
Three cards in a row displaying:
- **Steps**: 6504 (Blue, Running icon)
- **Calories**: 6504 (Orange, Fire icon)
- **Minutes**: 45 (Purple, Clock icon)

**Card Style**:
- Background: White
- Border radius: 16px
- Shadow: Black 5% opacity, 10px blur
- Padding: 16px
- Icon container: Colored background (10% opacity), 8px radius
- Value: headlineMedium, bold, black
- Label: bodyMedium, grey 600

### 3. Streak Card
- **Content**: "5-Day Streak" with fire emoji
- **Message**: "You're on fire! Keep the momentum going."
- **Style**:
  - Gradient background: Light Blue 30% → Cyan 30%
  - Border radius: 16px
  - Padding: 20px
  - Fire icon: 48px, orange 400
  - Title: titleLarge, bold, black
  - Message: bodyMedium, grey 700

### 4. Quick Track Section
**Title**: "Quick Track" (titleLarge, bold)

**Grid Layout**: 2 columns × 3 rows
- Cross spacing: 12px
- Main spacing: 12px
- Aspect ratio: 1.3

**Quick Track Cards** (6 total):
1. **Live Heart Rate** (Red) - Routes to `/home`
   - "Monitor from watch"
   - Heart Pulse icon
   
2. **Activity AI** (Deep Purple) - Routes to `/trackertest`
   - "Test TFLite model"
   - CPU icon
   
3. **Log Water** (Cyan)
   - "Stay Hydrated"
   - Cup icon
   
4. **Add Meal** (Orange)
   - "Record your intake"
   - Restaurant icon
   
5. **Log Sleep** (Purple)
   - "Track your rest"
   - Moon icon
   
6. **Track Workout** (Blue)
   - "Start a new session"
   - Running icon

**Card Style**:
- Background: White
- Border radius: 16px
- Shadow: Black 5% opacity, 10px blur
- Padding: 16px
- Icon container: Colored background (10% opacity), 10px radius, 28px icon
- Title: titleMedium, bold, black
- Subtitle: bodySmall, grey 600

---

## 📊 Other Tabs (Placeholder States)

### Activity Tab
- **Status**: Coming soon
- **Layout**: Centered placeholder
- **Icon**: Heart Pulse (64px, grey 400)
- **Title**: "Activity Tracking"
- **Subtitle**: "Coming soon"

### Track Tab
- **Status**: Coming soon
- **Layout**: Centered placeholder
- **Icon**: Target (64px, grey 400)
- **Title**: "Track Your Goals"
- **Subtitle**: "Coming soon"

### Progress Tab
- **Status**: Coming soon
- **Layout**: Centered placeholder
- **Icon**: Chart Square (64px, grey 400)
- **Title**: "Your Progress"
- **Subtitle**: "Coming soon"

### Profile Tab
- **Status**: Coming soon
- **Layout**: Centered placeholder
- **Icon**: User (64px, grey 400)
- **Title**: "Your Profile"
- **Subtitle**: "Coming soon"

---

## 🎨 Design System & Styling

### Color Palette
```dart
Primary Blue:  #3B82F6
Light Blue:    #5DADE2
Cyan:          #5DD9E2
Black:         #000000
White:         #FFFFFF
Light Gray:    #F5F5F5
Dark Gray:     #6B7280
```

### Typography (General Sans Font)
- **Display Large**: 57px, bold, -0.25 letter spacing
- **Display Medium**: 45px, bold
- **Display Small**: 36px, bold
- **Headline Large**: 32px, bold
- **Headline Medium**: 28px, w600
- **Headline Small**: 24px, w600
- **Title Large**: 22px, w600
- **Title Medium**: 16px, w600, 0.15 letter spacing
- **Title Small**: 14px, w600, 0.1 letter spacing
- **Body Large**: 16px, normal, 0.5 letter spacing
- **Body Medium**: 14px, normal, 0.25 letter spacing
- **Body Small**: 12px, normal, 0.4 letter spacing

### Component Styles

#### Cards
- Elevation: 2
- Border radius: 16px
- Background: White
- Shadow: Subtle (black 5% opacity)

#### Buttons
**Elevated Button**:
- Background: Primary Blue
- Foreground: White
- Padding: 24px horizontal, 16px vertical
- Border radius: 12px
- Font: 16px, w600, 0.5 letter spacing
- Elevation: 0

**Outlined Button**:
- Foreground: Primary Blue
- Border: 2px Primary Blue
- Padding: 24px horizontal, 16px vertical
- Border radius: 12px
- Font: 16px, w600, 0.5 letter spacing

**Text Button**:
- Foreground: Primary Blue
- Padding: 16px horizontal, 12px vertical
- Font: 14px, w600, 0.1 letter spacing

#### Icons
- **Library**: Solar Icons (Iconify)
- **Variants**: Outline (unselected), Bold (selected/active)
- **Sizes**: 16px (small), 20px (medium), 28px (large), 48-64px (hero)

---

## 🔄 Navigation Routes

### Current Route Map
```dart
'/'              → LoadingScreen
'/welcome'       → WelcomeScreen
'/login'         → LoginScreen
'/signup'        → SignUpScreen
'/survey1'       → SurveyScreen1
'/survey2'       → SurveyScreen2
'/survey3'       → SurveyScreen3
'/onboarding1'   → OnboardingScreen
'/dashboard'     → DashboardScreen (Main Hub)
'/trackertest'   → TrackerPage (Activity AI)
'/home'          → PhoneHomePage (Live Heart Rate)
```

### Navigation Patterns
- **Initial**: Auto-navigation from loading screen
- **Auth Flow**: Welcome → Signup/Login → Surveys → Onboarding → Dashboard
- **Main App**: Bottom navigation within DashboardScreen
- **Deep Links**: Quick Track cards navigate to specific features

---

## 🚨 Current Issues & Improvement Areas

### 1. Navigation Inconsistencies
- Login button currently routes to `/trackertest` instead of actual login
- No clear back navigation from deep-linked screens
- Missing navigation state management

### 2. Home Tab Issues
- **Hardcoded Data**: Stats show static values (6504 steps, 6504 calories, 45 minutes)
- **Hardcoded User**: Greeting always says "Jim"
- **Non-functional Cards**: Only 2 of 6 Quick Track cards have routes
- **No Data Integration**: Stats don't reflect actual user data

### 3. Placeholder Tabs
- 4 out of 5 tabs show "Coming soon" placeholders
- No actual functionality beyond Home tab
- Inconsistent user experience

### 4. UI/UX Concerns
- **Visual Hierarchy**: Stats cards could be more prominent
- **Information Density**: Home screen feels cluttered with 6 Quick Track cards
- **Spacing**: Some sections could use better breathing room
- **Feedback**: No loading states or error handling visible
- **Empty States**: No guidance when user has no data

### 5. Styling Inconsistencies
- Mix of hardcoded colors and theme colors
- Some components don't follow the design system
- Inconsistent shadow usage

### 6. Accessibility
- No visible focus indicators
- Color contrast may be insufficient in some areas
- No screen reader support evident

### 7. Performance
- SingleChildScrollView with GridView inside (not optimal)
- No lazy loading for Quick Track cards
- Missing image optimization

---

## 💡 Recommended Improvements

### High Priority
1. **Connect Real Data**: Replace hardcoded stats with actual user data
2. **Complete Navigation**: Implement proper auth flow and deep linking
3. **Implement Remaining Tabs**: Build out Activity, Track, Progress, and Profile
4. **Add Loading States**: Show skeleton screens while data loads
5. **Error Handling**: Add error states and retry mechanisms

### Medium Priority
6. **Personalization**: Dynamic greetings based on time and user name
7. **Empty States**: Design helpful empty states for new users
8. **Animations**: Add micro-interactions for better feedback
9. **Accessibility**: Implement proper semantic labels and focus management
10. **Responsive Design**: Optimize for different screen sizes

### Low Priority
11. **Dark Mode**: Ensure all screens work well in dark mode
12. **Haptic Feedback**: Add tactile feedback for interactions
13. **Onboarding Skip**: Save onboarding completion state
14. **Quick Actions**: Add swipe gestures or long-press menus

---

## 📐 Layout Measurements

### Spacing Scale
- Extra Small: 4px
- Small: 8px
- Medium: 12px
- Large: 16px
- Extra Large: 20px
- XXL: 24px
- XXXL: 32px

### Screen Padding
- Default: 20px
- Cards: 16px internal padding
- Buttons: 24px horizontal, 16px vertical

### Border Radius
- Small: 8px
- Medium: 12px
- Large: 16px
- Extra Large: 20px
- Circle: 50%

---

## 🎯 User Experience Flow Summary

**Current Flow**:
1. User opens app → Sees loading screen (3s)
2. Lands on welcome screen → Can signup or "login"
3. After auth → Goes through onboarding (3 screens)
4. Arrives at dashboard → Sees Home tab with stats and Quick Track
5. Can navigate between 5 tabs (only Home is functional)
6. Can tap Quick Track cards (only 2 work: Heart Rate and Activity AI)

**Ideal Flow** (Recommended):
1. User opens app → Quick splash (1s)
2. Check auth state → If logged in, go to dashboard; if not, show welcome
3. New users → Streamlined signup → Brief onboarding (skippable)
4. Dashboard → All tabs functional with real data
5. Quick actions → All cards navigate to working features
6. Smooth transitions → Proper back navigation and state management

---

## 📝 Notes

- The app uses Material 3 design system
- Solar Icons library provides consistent iconography
- Theme supports both light and dark modes
- Bottom navigation is the primary navigation pattern
- Cards are the primary content container pattern
- Gradient backgrounds used for branding moments (splash, welcome)

---

**Last Updated**: November 26, 2025
**Version**: 1.0
**Status**: Current Implementation Analysis
