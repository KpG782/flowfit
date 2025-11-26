# Design Document

## Overview

The FlowFit Dashboard Redesign implements a modern, reactive home screen using Flutter's Material 3 design system, Riverpod state management, and the Solar Icons library. The architecture follows a modular widget-based approach with clear separation of concerns between UI components, state management, and data models.

The dashboard consists of four main sections:
1. **Header** - App branding and notification indicator
2. **Stats Section** - Daily activity metrics (steps, calories, active time)
3. **CTA Section** - Quick action buttons for starting workouts
4. **Recent Activity Section** - List of recent workout history

All components are designed to be reusable, testable, and consistent with the existing AppTheme design system.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    HomeScreen (Root)                     │
│                  (ConsumerWidget)                        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐         ┌──────────────────┐
│  Scaffold    │         │  Riverpod        │
│  Structure   │◄────────┤  Providers       │
└──────┬───────┘         └──────────────────┘
       │
       ├─► HomeHeader (AppBar)
       │   └─► Notification Badge
       │
       ├─► RefreshIndicator
       │   └─► SingleChildScrollView
       │       │
       │       ├─► StatsSection
       │       │   ├─► StepsCard (full width)
       │       │   └─► Row
       │       │       ├─► CompactStatsCard (Calories)
       │       │       └─► CompactStatsCard (Active Time)
       │       │
       │       ├─► CTASection
       │       │   ├─► ElevatedButton (Start Workout)
       │       │   ├─► OutlinedButton (Log Run)
       │       │   └─► OutlinedButton (Record Walk)
       │       │
       │       └─► RecentActivitySection
       │           └─► ListView
       │               └─► ActivityCard (repeated)
       │
       └─► BottomNavigationBar (5 items)
```

### State Management Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Riverpod Providers                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  FutureProvider<DailyStats>                             │
│  ├─► Fetches: steps, stepsGoal, calories, activeMinutes│
│  └─► States: loading, data, error                       │
│                                                          │
│  FutureProvider<List<RecentActivity>>                   │
│  ├─► Fetches: recent workout history                    │
│  └─► States: loading, data, error                       │
│                                                          │
│  StateProvider<int> (selectedNavIndex)                  │
│  └─► Manages: bottom navigation selection               │
│                                                          │
│  StateProvider<int> (unreadNotifications)               │
│  └─► Manages: notification badge count                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Widget Component Hierarchy

```
lib/
├── screens/
│   └── home/
│       ├── home_screen.dart (Main screen assembly)
│       └── widgets/
│           ├── home_header.dart (AppBar with notifications)
│           ├── stats_section.dart (Stats cards container)
│           ├── cta_section.dart (Action buttons)
│           └── recent_activity_section.dart (Activity list)
│
├── providers/
│   └── dashboard_providers.dart (All Riverpod providers)
│
├── models/
│   ├── daily_stats.dart (DailyStats data model)
│   └── recent_activity.dart (RecentActivity data model)
│
└── theme/
    └── app_theme.dart (Existing theme system)
```

## Components and Interfaces

### 1. Data Models

#### DailyStats Model
```dart
class DailyStats {
  final int steps;
  final int stepsGoal;
  final int calories;
  final int activeMinutes;
  
  DailyStats({
    required this.steps,
    required this.stepsGoal,
    required this.calories,
    required this.activeMinutes,
  });
  
  double get stepsProgress => steps / stepsGoal;
}
```

**Purpose**: Encapsulates daily fitness metrics
**Computed Properties**: `stepsProgress` calculates percentage completion

#### RecentActivity Model
```dart
class RecentActivity {
  final String id;
  final String name;
  final String type; // 'run', 'walk', 'workout', 'cycle'
  final String details;
  final DateTime date;
  
  RecentActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    required this.date,
  });
  
  String get dateLabel {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}
```

**Purpose**: Represents a single workout activity
**Computed Properties**: `dateLabel` formats date based on recency

### 2. Riverpod Providers

#### dailyStatsProvider (FutureProvider)
```dart
final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  // Fetch from data source (Supabase, SQLite, etc.)
  // Returns DailyStats object
});
```

**Responsibility**: Asynchronously fetch daily statistics
**States**: loading, data(DailyStats), error
**Refresh**: Triggered by pull-to-refresh gesture

#### recentActivitiesProvider (FutureProvider)
```dart
final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((ref) async {
  // Fetch recent activities from data source
  // Returns list of RecentActivity objects
});
```

**Responsibility**: Asynchronously fetch recent workout history
**States**: loading, data(List<RecentActivity>), error
**Refresh**: Triggered by pull-to-refresh gesture

#### selectedNavIndexProvider (StateProvider)
```dart
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);
```

**Responsibility**: Track currently selected bottom navigation item
**Initial Value**: 0 (Home)
**Range**: 0-4 (5 navigation items)

#### unreadNotificationsProvider (StateProvider)
```dart
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
```

**Responsibility**: Track unread notification count
**Initial Value**: 0
**Display Logic**: Shows "9+" when count > 9

### 3. Widget Components

#### HomeScreen (Root Component)
- **Type**: ConsumerWidget
- **Responsibilities**:
  - Assemble all dashboard sections
  - Implement pull-to-refresh
  - Manage bottom navigation
  - Handle navigation routing
- **State Dependencies**: All providers
- **Navigation Routes**:
  - `/active` - Workout tracking
  - `/health` - Health metrics
  - `/track` - Activity tracking center
  - `/analytics` - Progress analytics
  - `/profile` - User profile
  - `/notifications` - Notifications screen

#### HomeHeader Widget
- **Type**: ConsumerWidget
- **Responsibilities**:
  - Display app branding ("FlowFit")
  - Show notification bell icon
  - Display notification badge with count
- **State Dependencies**: unreadNotificationsProvider
- **Styling**:
  - Background: theme.colorScheme.surface
  - Title: theme.textTheme.headlineMedium (bold)
  - Badge: theme.colorScheme.error background
  - Icon size: 24dp

#### StatsSection Widget
- **Type**: ConsumerWidget
- **Responsibilities**:
  - Display "Track Your Activity" section header
  - Render StepsCard (full width)
  - Render two-column grid (Calories, Active Time)
  - Handle loading states (skeleton placeholders)
  - Handle error states (error message)
- **State Dependencies**: dailyStatsProvider
- **Child Components**:
  - StepsCard
  - CompactStatsCard (x2)

#### StepsCard Widget
- **Type**: StatelessWidget
- **Props**: DailyStats stats
- **Responsibilities**:
  - Display steps icon, label, current/goal values
  - Render progress bar
  - Show percentage completion
- **Styling**:
  - Full width card
  - 16px padding, 16px border radius
  - Icon container: 10% opacity of primary color
  - Progress bar: theme.colorScheme.primary

#### CompactStatsCard Widget
- **Type**: StatelessWidget
- **Props**: IconData icon, String value, String label, Color color
- **Responsibilities**:
  - Display metric icon, value, and label
- **Styling**:
  - Half width (in Row with Expanded)
  - 16px padding, 16px border radius
  - Icon container: 10% opacity of accent color

#### CTASection Widget
- **Type**: StatelessWidget
- **Responsibilities**:
  - Display "Ready to move?" section header
  - Render three action buttons
  - Handle navigation with pre-selected activity types
- **Buttons**:
  1. Primary: "Start a Workout" (ElevatedButton)
  2. Secondary: "Log a Run" (OutlinedButton)
  3. Secondary: "Record a Walk" (OutlinedButton)
- **Styling**:
  - Button height: 56dp
  - Border radius: 16px
  - Full width buttons
  - 12px spacing between buttons

#### RecentActivitySection Widget
- **Type**: ConsumerWidget
- **Responsibilities**:
  - Display "Your Recent Activity" section header
  - Render list of ActivityCard widgets
  - Handle loading states (skeleton placeholders)
  - Handle error states (error message)
  - Handle empty states ("No activity yet today")
- **State Dependencies**: recentActivitiesProvider
- **Child Components**: ActivityCard (repeated)

#### ActivityCard Widget
- **Type**: StatelessWidget
- **Props**: RecentActivity activity
- **Responsibilities**:
  - Display activity icon, name, details, date
  - Map activity type to icon and color
  - Handle tap navigation to activity details
- **Activity Type Mappings**:
  - run → SolarIcons.running, primary color
  - walk → SolarIcons.walking, green (#10B981)
  - workout → SolarIcons.dumbbells, error color
  - cycle → SolarIcons.bicycling, purple (#9333EA)
- **Styling**:
  - 16px padding, 12px border radius
  - Icon container: 48x48dp, 12px radius
  - InkWell for ripple effect

### 4. Bottom Navigation Bar

#### Configuration
- **Item Count**: Exactly 5 items
- **Items** (in order):
  1. Home (SolarIcons.home2 or homeSmile)
  2. Health (SolarIcons.heartPulse or heartbeat)
  3. Track (SolarIcons.mapPointWave or routing2)
  4. Progress (SolarIcons.chartSquare or graph)
  5. Profile (SolarIcons.userCircle or user)

#### Styling
- **Height**: 72px
- **Icon Size**: 24px
- **Selected Color**: theme.colorScheme.primary
- **Unselected Color**: theme.colorScheme.onSurfaceVariant
- **Label Font**: theme.textTheme.bodySmall
- **Elevation**: 8
- **Background**: theme.colorScheme.surface

#### Icon Fallback Strategy
1. Try Solar Icons first
2. If not available, fall back to Material Icons
3. Maintain consistent visual weight

## Data Models

### DailyStats
```dart
class DailyStats {
  final int steps;           // Current step count
  final int stepsGoal;       // Daily step goal
  final int calories;        // Calories burned today
  final int activeMinutes;   // Active minutes today
  
  double get stepsProgress;  // Computed: steps / stepsGoal
}
```

**Data Source**: Fetched from local database (SQLite) or backend (Supabase)
**Update Frequency**: Real-time or on pull-to-refresh
**Validation**: All values must be non-negative integers

### RecentActivity
```dart
class RecentActivity {
  final String id;           // Unique activity identifier
  final String name;         // Activity name (e.g., "Morning Run")
  final String type;         // Activity type: 'run', 'walk', 'workout', 'cycle'
  final String details;      // Activity details (e.g., "3.2 miles • 30 min")
  final DateTime date;       // Activity completion date
  
  String get dateLabel;      // Computed: "Today", "Yesterday", or "MMM d"
}
```

**Data Source**: Fetched from local database (SQLite) or backend (Supabase)
**Sorting**: Most recent first
**Limit**: Display last 10-15 activities
**Validation**: 
- `type` must be one of: 'run', 'walk', 'workout', 'cycle'
- `date` must not be in the future

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After analyzing all acceptance criteria, I've identified several areas where properties can be consolidated:

**Redundancy Analysis:**
- Properties 4.3, 4.4, and 4.5 (date label formatting) can be combined into a single comprehensive date formatting property
- Properties 6.3, 6.4, 6.5, and 6.8 (card styling) can be combined into a single card consistency property
- Properties 7.3 and 7.4 (badge text) can be combined into a single badge formatting property
- Properties 2.1, 2.2, and 2.3 (stats display) are similar but test different metrics, so they should remain separate

**Consolidated Properties:**
The following properties provide unique validation value and will be implemented:

1. Stats card information completeness (combines 2.1, 2.2, 2.3)
2. Activity information completeness (4.2)
3. Date label formatting (combines 4.3, 4.4, 4.5)
4. Navigation behavior (3.4, 3.5, 3.6, 4.6)
5. Activity type visual mapping (4.8)
6. Card styling consistency (combines 6.3, 6.4, 6.5, 6.8)
7. Theme usage consistency (6.1, 6.2, 6.7)
8. Notification badge formatting (combines 7.3, 7.4)
9. Provider state handling (5.5, 5.6, 5.7)
10. Section spacing consistency (9.4)

### Correctness Properties

Property 1: Stats card information completeness
*For any* DailyStats object, when rendered in the stats section, the UI should display steps (current and goal), calories, active minutes, and progress percentage
**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Activity information completeness
*For any* RecentActivity object, when rendered as an activity card, the UI should display the activity name, type icon, details, and date label
**Validates: Requirements 4.2**

Property 3: Date label formatting correctness
*For any* RecentActivity with a date, the dateLabel should be "Today" if the date is today, "Yesterday" if the date is yesterday, and "MMM d" format if the date is more than one day ago
**Validates: Requirements 4.3, 4.4, 4.5**

Property 4: Navigation with correct parameters
*For any* CTA button tap (Start Workout, Log Run, Record Walk), the navigation should occur to the correct route with the appropriate activity type parameter (if applicable)
**Validates: Requirements 3.4, 3.5, 3.6**

Property 5: Activity card navigation
*For any* activity card tap, the dashboard should navigate to the activity details screen with the correct activity ID
**Validates: Requirements 4.6**

Property 6: Activity type visual consistency
*For any* activity type ('run', 'walk', 'workout', 'cycle'), the activity card should consistently use the same icon and color for that type across all instances
**Validates: Requirements 4.8**

Property 7: Card styling consistency
*For any* card component in the dashboard, it should have 16px border radius, 16px padding, elevation 2 shadow, and theme.colorScheme.surface background
**Validates: Requirements 6.3, 6.4, 6.5, 6.8**

Property 8: Theme usage consistency
*For any* color or text style used in the dashboard, it should come from theme.colorScheme or theme.textTheme respectively
**Validates: Requirements 6.1, 6.2**

Property 9: Icon sizing consistency
*For any* icon in navigation or card components, it should be 24 density-independent pixels
**Validates: Requirements 6.7**

Property 10: Button sizing consistency
*For any* button in the CTA section, it should have a height of 56 density-independent pixels
**Validates: Requirements 6.6**

Property 11: Notification badge formatting
*For any* unread notification count, if count > 9 then badge displays "9+", if count > 0 and count <= 9 then badge displays exact count, if count = 0 then no badge is displayed
**Validates: Requirements 7.2, 7.3, 7.4**

Property 12: Provider loading state handling
*For any* FutureProvider in loading state, the dashboard should display appropriate loading UI (skeleton placeholders)
**Validates: Requirements 2.6, 5.6**

Property 13: Provider error state handling
*For any* FutureProvider in error state, the dashboard should display an appropriate error message
**Validates: Requirements 2.7, 5.7**

Property 14: Provider reactivity
*For any* provider data change, all widgets watching that provider should automatically rebuild with the new data
**Validates: Requirements 5.5**

Property 15: Refresh triggers provider updates
*For any* pull-to-refresh gesture, all FutureProviders (dailyStats and recentActivities) should be invalidated and refetched
**Validates: Requirements 8.2**

Property 16: Refresh completion handling
*For any* completed refresh operation, if successful then loading indicator hides and updated data displays, if failed then error message displays and loading indicator hides
**Validates: Requirements 8.4, 8.5**

Property 17: Section spacing consistency
*For any* two adjacent sections in the dashboard, they should be separated by at least 24 density-independent pixels
**Validates: Requirements 9.4**

Property 18: Section header styling consistency
*For any* section header, it should use theme.textTheme.titleLarge or headlineSmall and have bold font weight
**Validates: Requirements 9.5, 9.6**

Property 19: Activity list rendering
*For any* list of recent activities, all activities in the list should be rendered as activity cards
**Validates: Requirements 4.1**

## Error Handling

### Provider Error States

**dailyStatsProvider Errors:**
- **Network Failure**: Display "Failed to load stats. Pull to refresh." in error container
- **Data Parsing Error**: Display "Unable to load activity data. Please try again."
- **Timeout**: Display "Request timed out. Pull to refresh."
- **Recovery**: User can pull-to-refresh to retry

**recentActivitiesProvider Errors:**
- **Network Failure**: Display "Failed to load activities" in error container
- **Empty Data**: Display empty state with "No activity yet today" message
- **Data Parsing Error**: Display "Unable to load activity history."
- **Recovery**: User can pull-to-refresh to retry

### Navigation Errors

**Route Not Found:**
- Fallback to home screen
- Log error for debugging
- Display snackbar: "Screen not available"

**Invalid Activity Type:**
- Default to generic "workout" type
- Log warning for debugging
- Continue with navigation

### UI Error Boundaries

**Widget Build Errors:**
- Catch errors in individual widget builds
- Display fallback UI for that section
- Log error details
- Prevent entire screen crash

**Theme Access Errors:**
- Fallback to Material default colors
- Log warning
- Continue rendering

### Data Validation

**DailyStats Validation:**
- Ensure steps >= 0 and stepsGoal > 0
- Ensure calories >= 0
- Ensure activeMinutes >= 0
- If invalid, use default values (0 for metrics, 10000 for goal)

**RecentActivity Validation:**
- Ensure activity type is one of: 'run', 'walk', 'workout', 'cycle'
- Ensure date is not in the future
- Ensure required fields (id, name, type, details, date) are present
- If invalid, skip rendering that activity

## Testing Strategy

### Unit Testing Approach

The dashboard will use a combination of unit tests and property-based tests to ensure correctness.

**Unit Tests** will cover:
- Specific widget rendering scenarios
- Edge cases (empty lists, zero values, boundary conditions)
- Error state handling
- Navigation routing
- Date formatting edge cases (midnight boundaries, timezone handling)

**Property-Based Tests** will cover:
- Universal properties that should hold across all inputs
- Data model computed properties (stepsProgress, dateLabel)
- Theme consistency across all components
- Styling consistency across all cards
- Provider state transitions

### Property-Based Testing Framework

**Framework**: Use the `test` package with custom property test utilities for Flutter
**Minimum Iterations**: 100 runs per property test
**Test Tagging**: Each property-based test must include a comment with the format:
```dart
// **Feature: dashboard-redesign, Property X: [property description]**
```

### Testing Libraries

- **flutter_test**: Core Flutter testing framework
- **mockito**: For mocking providers and data sources
- **flutter_riverpod**: ProviderContainer for testing providers
- **golden_toolkit**: For visual regression testing (optional)

### Test Organization

```
test/
├── screens/
│   └── home/
│       ├── home_screen_test.dart
│       └── widgets/
│           ├── home_header_test.dart
│           ├── stats_section_test.dart
│           ├── cta_section_test.dart
│           └── recent_activity_section_test.dart
│
├── providers/
│   └── dashboard_providers_test.dart
│
├── models/
│   ├── daily_stats_test.dart
│   └── recent_activity_test.dart
│
└── property_tests/
    ├── stats_display_properties_test.dart
    ├── activity_display_properties_test.dart
    ├── theme_consistency_properties_test.dart
    ├── navigation_properties_test.dart
    └── provider_state_properties_test.dart
```

### Unit Test Coverage

**HomeScreen Tests:**
- Renders all sections correctly
- Pull-to-refresh triggers provider refresh
- Bottom navigation updates selected index
- Navigation routing works correctly
- Empty state handling

**HomeHeader Tests:**
- Displays app title
- Shows notification icon
- Badge displays correct count
- Badge shows "9+" for counts > 9
- Badge hidden when count is 0
- Navigation to notifications screen

**StatsSection Tests:**
- Displays section header
- Renders StepsCard with correct data
- Renders CompactStatsCards in two-column layout
- Shows loading skeleton when data is loading
- Shows error message when data fails to load
- Handles zero values gracefully

**CTASection Tests:**
- Displays section header
- Renders all three buttons
- Primary button navigates to /active
- Secondary buttons navigate with correct activity type
- Button styling matches theme

**RecentActivitySection Tests:**
- Displays section header
- Renders activity cards for each activity
- Shows empty state when no activities
- Shows loading skeleton when data is loading
- Shows error message when data fails to load
- Activity card tap navigates to details

**Provider Tests:**
- dailyStatsProvider fetches and returns data
- recentActivitiesProvider fetches and returns data
- selectedNavIndexProvider updates correctly
- unreadNotificationsProvider updates correctly
- Provider refresh invalidates cache

**Model Tests:**
- DailyStats.stepsProgress calculates correctly
- RecentActivity.dateLabel formats "Today" correctly
- RecentActivity.dateLabel formats "Yesterday" correctly
- RecentActivity.dateLabel formats "MMM d" correctly
- Edge cases: midnight boundaries, leap years

### Property-Based Test Coverage

**Property Test 1: Stats Display Completeness**
```dart
// **Feature: dashboard-redesign, Property 1: Stats card information completeness**
// Generate random DailyStats objects
// Render stats section
// Verify all required information is displayed
```

**Property Test 2: Activity Display Completeness**
```dart
// **Feature: dashboard-redesign, Property 2: Activity information completeness**
// Generate random RecentActivity objects
// Render activity cards
// Verify all required information is displayed
```

**Property Test 3: Date Label Formatting**
```dart
// **Feature: dashboard-redesign, Property 3: Date label formatting correctness**
// Generate random dates (today, yesterday, past dates)
// Create RecentActivity objects with those dates
// Verify dateLabel matches expected format
```

**Property Test 4: Activity Type Visual Consistency**
```dart
// **Feature: dashboard-redesign, Property 6: Activity type visual consistency**
// Generate multiple activities of the same type
// Render activity cards
// Verify all cards of same type use same icon and color
```

**Property Test 5: Card Styling Consistency**
```dart
// **Feature: dashboard-redesign, Property 7: Card styling consistency**
// Render all card types (steps, calories, active time, activity cards)
// Verify all have 16px border radius, 16px padding, elevation 2, surface background
```

**Property Test 6: Theme Usage Consistency**
```dart
// **Feature: dashboard-redesign, Property 8: Theme usage consistency**
// Render dashboard with custom theme
// Verify all colors come from theme.colorScheme
// Verify all text styles come from theme.textTheme
```

**Property Test 7: Icon Sizing Consistency**
```dart
// **Feature: dashboard-redesign, Property 9: Icon sizing consistency**
// Render dashboard
// Find all icons in navigation and cards
// Verify all are 24dp
```

**Property Test 8: Button Sizing Consistency**
```dart
// **Feature: dashboard-redesign, Property 10: Button sizing consistency**
// Render CTA section
// Find all buttons
// Verify all have 56dp height
```

**Property Test 9: Notification Badge Formatting**
```dart
// **Feature: dashboard-redesign, Property 11: Notification badge formatting**
// Generate random notification counts (0, 1-9, 10+)
// Render header
// Verify badge displays correctly for each range
```

**Property Test 10: Provider State Handling**
```dart
// **Feature: dashboard-redesign, Property 12-13: Provider loading and error state handling**
// Create providers in loading state
// Verify loading UI is displayed
// Create providers in error state
// Verify error UI is displayed
```

**Property Test 11: Provider Reactivity**
```dart
// **Feature: dashboard-redesign, Property 14: Provider reactivity**
// Create provider with initial data
// Render dashboard
// Update provider data
// Verify UI automatically updates
```

**Property Test 12: Section Spacing Consistency**
```dart
// **Feature: dashboard-redesign, Property 17: Section spacing consistency**
// Render dashboard
// Measure spacing between all adjacent sections
// Verify all spacing >= 24dp
```

### Test Execution Strategy

1. **Development Phase**: Run unit tests on every file save
2. **Pre-Commit**: Run all unit tests and property tests
3. **CI/CD Pipeline**: Run full test suite including property tests with 100 iterations
4. **Coverage Target**: Aim for 80%+ code coverage on business logic
5. **Visual Regression**: Run golden tests on major UI changes

### Mock Data Strategy

**Test Data Generators:**
- Create factory functions for generating valid DailyStats objects
- Create factory functions for generating valid RecentActivity objects
- Use randomized but valid data for property tests
- Use specific edge case data for unit tests

**Provider Mocking:**
- Use ProviderContainer with overrides for testing
- Mock data sources (Supabase, SQLite) to return test data
- Test both success and failure scenarios

## Implementation Notes

### File Structure

```
lib/
├── screens/
│   └── home/
│       ├── home_screen.dart (250-300 lines)
│       └── widgets/
│           ├── home_header.dart (80-100 lines)
│           ├── stats_section.dart (200-250 lines)
│           ├── cta_section.dart (100-120 lines)
│           └── recent_activity_section.dart (200-250 lines)
│
├── providers/
│   └── dashboard_providers.dart (100-150 lines)
│
├── models/
│   ├── daily_stats.dart (30-40 lines)
│   └── recent_activity.dart (40-50 lines)
│
└── theme/
    └── app_theme.dart (existing file)
```

### Dependencies

**Required Packages** (already in pubspec.yaml):
- flutter_riverpod: ^2.6.1
- solar_icons: ^0.0.5
- intl: ^0.18.1 (for date formatting)
- go_router: ^13.2.5 (for navigation)

**No Additional Packages Needed**

### Performance Considerations

**Widget Rebuilds:**
- Use ConsumerWidget only where provider data is needed
- Use const constructors where possible
- Minimize widget tree depth

**List Performance:**
- Use ListView.builder for activity list (not ListView with children)
- Implement shrinkWrap: true and physics: NeverScrollableScrollPhysics for nested lists
- Limit recent activities to 10-15 items

**Provider Optimization:**
- Use FutureProvider for async data (auto-caches results)
- Implement proper provider disposal
- Avoid unnecessary provider refreshes

**Image/Icon Loading:**
- Solar Icons are vector-based (no loading delay)
- Use const IconData where possible
- Preload any custom icons

### Accessibility Considerations

**Semantic Labels:**
- Add Semantics widgets to all interactive elements
- Provide meaningful labels for screen readers
- Use Tooltip widgets for icon-only buttons

**Color Contrast:**
- Ensure text meets WCAG AA standards (4.5:1 for normal text)
- Test with theme colors to verify contrast
- Provide alternative indicators beyond color (icons, text)

**Touch Targets:**
- Minimum 48x48dp touch targets for all interactive elements
- Add padding around small icons to increase touch area
- Use InkWell/InkResponse for visual feedback

**Screen Reader Support:**
- Announce loading states
- Announce error states
- Provide context for navigation actions

### Internationalization (i18n)

**Localizable Strings:**
- "FlowFit" (app name)
- "Track Your Activity"
- "Ready to move?"
- "Your Recent Activity"
- "Start a Workout"
- "Log a Run"
- "Record a Walk"
- "Today", "Yesterday"
- "No activity yet today"
- "Let's get started!"
- Error messages

**Date Formatting:**
- Use intl package for locale-aware date formatting
- "MMM d" format should adapt to user's locale
- Consider 12/24 hour time format preferences

### Dark Mode Support

**Theme Switching:**
- Dashboard automatically adapts to theme.colorScheme
- No hardcoded colors (all from theme)
- Test both light and dark themes
- Ensure sufficient contrast in both modes

**Color Adjustments:**
- Dark mode uses theme.colorScheme.surface (0xFF1F1F1F)
- Card shadows may need adjustment in dark mode
- Icon colors automatically adapt via theme

### Migration Strategy

**Existing Dashboard:**
- Identify current home screen implementation
- Create new dashboard alongside existing (feature flag)
- Gradually migrate users to new dashboard
- Deprecate old dashboard after testing period

**Data Migration:**
- No data migration needed (same data sources)
- Ensure backward compatibility with existing data models
- Test with production data samples

**Navigation Migration:**
- Update navigation routes if needed
- Ensure deep links still work
- Test all navigation paths

### Future Enhancements

**Potential Additions:**
- Animated transitions between sections
- Swipe gestures on activity cards (delete, edit)
- Customizable dashboard sections (drag to reorder)
- Widget-based dashboard (add/remove sections)
- Real-time activity updates (WebSocket)
- Offline mode with sync indicator
- Achievement badges on dashboard
- Social features (friend activity feed)

**Performance Optimizations:**
- Implement pagination for activity list
- Add infinite scroll for older activities
- Cache rendered widgets
- Optimize provider refresh strategy

**Analytics Integration:**
- Track button taps
- Track navigation patterns
- Track pull-to-refresh usage
- Track error occurrences

## Design Decisions and Rationale

### Why Riverpod over Provider?

- **Better testability**: ProviderContainer makes testing easier
- **Compile-time safety**: Catches errors at compile time
- **No BuildContext required**: Can access providers anywhere
- **Better performance**: More granular rebuilds
- **Already in use**: Project already uses Riverpod

### Why Solar Icons?

- **Consistent design language**: Modern, clean icon set
- **Better fitness icons**: More relevant icons for fitness app
- **Lightweight**: Vector-based, no performance impact
- **Already in dependencies**: No additional package needed

### Why Modular Widgets?

- **Testability**: Each widget can be tested in isolation
- **Reusability**: Components can be reused in other screens
- **Maintainability**: Easier to update individual sections
- **Code organization**: Clear separation of concerns
- **Team collaboration**: Multiple developers can work on different widgets

### Why FutureProvider for Data?

- **Automatic caching**: Results are cached until invalidated
- **Loading states**: Built-in loading/error/data states
- **Refresh support**: Easy to invalidate and refetch
- **Error handling**: Automatic error state management
- **Async support**: Natural fit for async data fetching

### Why Pull-to-Refresh?

- **User expectation**: Standard pattern in mobile apps
- **Manual control**: Users can force data refresh
- **Visual feedback**: Clear indication of refresh action
- **Error recovery**: Easy way to retry after errors

### Why 5 Navigation Items?

- **Reduced cognitive load**: Fewer choices, easier navigation
- **Better UX**: Aligns with mobile best practices (3-5 items)
- **Thumb-friendly**: All items reachable with one hand
- **Clear hierarchy**: Focus on core features

### Why Card-Based Layout?

- **Visual hierarchy**: Clear separation of content
- **Scannable**: Easy to quickly scan information
- **Modern design**: Aligns with Material 3 guidelines
- **Flexible**: Easy to add/remove sections
- **Touch-friendly**: Clear touch targets

## Conclusion

This design provides a comprehensive blueprint for implementing the FlowFit Dashboard Redesign. The modular architecture, clear component boundaries, and robust state management ensure the dashboard will be maintainable, testable, and performant. The use of Riverpod for state management and adherence to the existing AppTheme system ensures consistency with the rest of the application while providing a modern, reactive user experience.
