# Requirements Document

## Introduction

The FlowFit Dashboard Redesign aims to create a cleaner, more focused home screen experience that emphasizes user activity tracking and quick access to workout features. The redesign will implement a 5-item bottom navigation system, display daily activity statistics in an intuitive card-based layout, provide prominent call-to-action buttons for starting workouts, and show recent activity history. The system will use Riverpod for state management and maintain consistency with the app's existing theme system (app_theme.dart) while incorporating Solar Icons as the primary icon library.

## Glossary

- **Dashboard**: The main home screen of the FlowFit application that displays activity summaries and navigation
- **Bottom Navigation Bar**: A persistent navigation component at the bottom of the screen with 5 items (Home, Health, Track, Progress, Profile)
- **Stats Card**: A visual component displaying a specific fitness metric (steps, calories, active time) with progress indicators
- **CTA Section**: Call-to-action section containing buttons for initiating workout activities
- **Recent Activity List**: A scrollable list showing the user's most recent completed workouts and activities
- **Riverpod**: The state management library used throughout the application
- **Solar Icons**: The primary icon library for the application interface
- **AppTheme**: The centralized theme configuration system defined in app_theme.dart
- **Daily Stats**: Aggregated fitness metrics for the current day including steps, calories, and active minutes
- **Activity Type**: A categorization of workout activities (run, walk, workout, cycle, etc.)

## Requirements

### Requirement 1

**User Story:** As a user, I want a simplified bottom navigation with exactly 5 items, so that I can quickly access the main sections of the app without clutter.

#### Acceptance Criteria

1. THE Dashboard SHALL display a bottom navigation bar with exactly 5 navigation items
2. WHEN the Dashboard loads THEN the bottom navigation bar SHALL display items in the following order: Home, Health, Track, Progress, Profile
3. THE Dashboard SHALL use Solar Icons as the primary icon library for navigation items
4. WHEN a Solar Icon is not available THEN the Dashboard SHALL fall back to Material Icons
5. THE Dashboard SHALL apply theme.colorScheme.primary color to the selected navigation item
6. THE Dashboard SHALL apply theme.colorScheme.onSurfaceVariant color to unselected navigation items

### Requirement 2

**User Story:** As a user, I want to see my daily activity statistics at a glance, so that I can quickly understand my progress toward my fitness goals.

#### Acceptance Criteria

1. THE Dashboard SHALL display a steps card showing current steps, goal steps, and progress percentage
2. THE Dashboard SHALL display a calories card showing calories burned for the current day
3. THE Dashboard SHALL display an active time card showing active minutes for the current day
4. THE Dashboard SHALL render the steps card as a full-width component with a progress bar
5. THE Dashboard SHALL render the calories and active time cards in a two-column grid layout
6. WHEN daily stats data is loading THEN the Dashboard SHALL display skeleton loading placeholders
7. WHEN daily stats data fails to load THEN the Dashboard SHALL display an error message with retry instructions

### Requirement 3

**User Story:** As a user, I want prominent buttons to start workouts, so that I can quickly begin tracking my physical activity.

#### Acceptance Criteria

1. THE Dashboard SHALL display a primary button labeled "Start a Workout"
2. THE Dashboard SHALL display a secondary outlined button labeled "Log a Run"
3. THE Dashboard SHALL display a secondary outlined button labeled "Record a Walk"
4. WHEN the user taps "Start a Workout" THEN the Dashboard SHALL navigate to the workout selection screen
5. WHEN the user taps "Log a Run" THEN the Dashboard SHALL navigate to the activity tracking screen with run type pre-selected
6. WHEN the user taps "Record a Walk" THEN the Dashboard SHALL navigate to the activity tracking screen with walk type pre-selected
7. THE Dashboard SHALL style the primary button with theme.colorScheme.primary background color
8. THE Dashboard SHALL style secondary buttons with theme.colorScheme.outline border color

### Requirement 4

**User Story:** As a user, I want to see my recent workout history on the home screen, so that I can review my recent activities without navigating to a separate screen.

#### Acceptance Criteria

1. THE Dashboard SHALL display a list of the user's recent activities
2. WHEN displaying an activity THEN the Dashboard SHALL show the activity name, type icon, details, and date label
3. WHEN the activity occurred today THEN the Dashboard SHALL display "Today" as the date label
4. WHEN the activity occurred yesterday THEN the Dashboard SHALL display "Yesterday" as the date label
5. WHEN the activity occurred more than one day ago THEN the Dashboard SHALL display the date in "MMM d" format
6. WHEN the user taps an activity card THEN the Dashboard SHALL navigate to the activity details screen
7. WHEN no recent activities exist THEN the Dashboard SHALL display an empty state message
8. THE Dashboard SHALL assign activity-specific colors and icons based on activity type

### Requirement 5

**User Story:** As a user, I want the app to use Riverpod for state management, so that the dashboard data updates reactively and efficiently.

#### Acceptance Criteria

1. THE Dashboard SHALL use Riverpod FutureProvider for fetching daily stats data
2. THE Dashboard SHALL use Riverpod FutureProvider for fetching recent activities data
3. THE Dashboard SHALL use Riverpod StateProvider for managing selected navigation index
4. THE Dashboard SHALL use Riverpod StateProvider for managing unread notification count
5. WHEN a provider's data changes THEN the Dashboard SHALL automatically rebuild affected widgets
6. THE Dashboard SHALL handle provider loading states with appropriate UI feedback
7. THE Dashboard SHALL handle provider error states with appropriate error messages

### Requirement 6

**User Story:** As a user, I want the dashboard to follow the app's design system, so that the interface feels consistent and polished.

#### Acceptance Criteria

1. THE Dashboard SHALL use theme.colorScheme values for all color assignments
2. THE Dashboard SHALL use theme.textTheme styles for all text components
3. THE Dashboard SHALL apply 16-pixel border radius to all card components
4. THE Dashboard SHALL apply 16-pixel padding to card interiors
5. THE Dashboard SHALL use elevation 2 shadows for card components
6. THE Dashboard SHALL set button heights to 56 density-independent pixels
7. THE Dashboard SHALL set icon sizes to 24 density-independent pixels for navigation and cards
8. THE Dashboard SHALL use theme.colorScheme.surface for card backgrounds

### Requirement 7

**User Story:** As a user, I want to see notifications indicated in the header, so that I am aware of important updates without leaving the home screen.

#### Acceptance Criteria

1. THE Dashboard SHALL display a notification bell icon in the app header
2. WHEN unread notifications exist THEN the Dashboard SHALL display a badge on the notification icon
3. WHEN the unread notification count exceeds 9 THEN the Dashboard SHALL display "9+" in the badge
4. WHEN the unread notification count is 9 or less THEN the Dashboard SHALL display the exact count in the badge
5. THE Dashboard SHALL style the notification badge with theme.colorScheme.error background color
6. WHEN the user taps the notification icon THEN the Dashboard SHALL navigate to the notifications screen

### Requirement 8

**User Story:** As a user, I want to refresh my dashboard data by pulling down, so that I can manually update my statistics and activity list.

#### Acceptance Criteria

1. THE Dashboard SHALL implement pull-to-refresh functionality on the main scroll view
2. WHEN the user performs a pull-down gesture THEN the Dashboard SHALL trigger a refresh of all provider data
3. WHEN data is refreshing THEN the Dashboard SHALL display a loading indicator
4. WHEN the refresh completes successfully THEN the Dashboard SHALL hide the loading indicator and display updated data
5. WHEN the refresh fails THEN the Dashboard SHALL display an error message and hide the loading indicator

### Requirement 9

**User Story:** As a user, I want the dashboard to be organized into clear sections, so that I can easily scan and find the information I need.

#### Acceptance Criteria

1. THE Dashboard SHALL display a "Track Your Activity" section header above the stats cards
2. THE Dashboard SHALL display a "Ready to move?" section header above the CTA buttons
3. THE Dashboard SHALL display a "Your Recent Activity" section header above the activity list
4. THE Dashboard SHALL separate sections with visual spacing of at least 24 density-independent pixels
5. THE Dashboard SHALL style section headers with theme.textTheme.titleLarge or theme.textTheme.headlineSmall
6. THE Dashboard SHALL apply bold font weight to all section headers

### Requirement 10

**User Story:** As a developer, I want the dashboard components to be modular and reusable, so that the codebase is maintainable and testable.

#### Acceptance Criteria

1. THE Dashboard SHALL implement the header as a separate HomeHeader widget
2. THE Dashboard SHALL implement the stats section as a separate StatsSection widget
3. THE Dashboard SHALL implement the CTA section as a separate CTASection widget
4. THE Dashboard SHALL implement the recent activity section as a separate RecentActivitySection widget
5. THE Dashboard SHALL implement individual stat cards as separate widget classes
6. THE Dashboard SHALL implement individual activity cards as separate widget classes
7. THE Dashboard SHALL define all Riverpod providers in a dedicated providers file
