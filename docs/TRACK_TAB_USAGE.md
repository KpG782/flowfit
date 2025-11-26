# Track Tab - Usage Documentation

## Overview
The **Track Tab** is the central hub for monitoring your daily fitness activities and starting new workouts. It provides real-time statistics, quick action buttons, and a history of your recent activities. This page is designed to give you a complete overview of your fitness journey at a glance.

---

## Page Structure

The Track Tab consists of three main sections:

1. **Stats Section** - Track Your Activity
2. **CTA Section** - Ready to move?
3. **Recent Activity Section** - Your Recent Activity

---

## 1. Stats Section - Track Your Activity

### Purpose
Displays your daily fitness statistics with visual progress indicators to help you monitor your goals throughout the day.

### Components

#### Steps Card (Full Width)
- **Icon**: Walking icon in a rounded container
- **Display**: Current steps / Goal steps (e.g., "6,504 / 10,000")
- **Progress Bar**: Visual indicator showing percentage of goal completed
- **Percentage**: Shows completion percentage (e.g., "65%")
- **Color**: Primary theme color (blue)

#### Calories Card (Compact)
- **Icon**: Fire icon in a rounded container
- **Display**: Total calories burned today
- **Label**: "Calories"
- **Color**: Red/Error theme color
- **Layout**: Half-width card (left side)

#### Active Minutes Card (Compact)
- **Icon**: Timer icon in a rounded container
- **Display**: Total active minutes today
- **Label**: "Active Minutes"
- **Color**: Tertiary theme color (purple/teal)
- **Layout**: Half-width card (right side)

### Features
- **Real-time Updates**: Stats refresh automatically as you track activities
- **Pull to Refresh**: Swipe down to manually refresh all statistics
- **Loading States**: Skeleton placeholders appear while data is loading
- **Error Handling**: Clear error messages with retry option if data fails to load

### Data Source
Stats are fetched from the `dailyStatsProvider` which aggregates:
- Step count from device sensors
- Calories burned from tracked activities
- Active minutes from workout sessions

---

## 2. CTA Section - Ready to move?

### Purpose
Provides quick access buttons to start tracking different types of physical activities.

### Buttons

#### 1. Start a Workout (Primary Button)
- **Style**: Filled button with primary color background
- **Action**: Opens the workout selection screen
- **Navigation**: Routes to `/active`
- **Use Case**: When you want to browse and select from available workout types
- **Visual**: Full-width, prominent button with white text

#### 2. Log a Run (Secondary Button)
- **Style**: Outlined button with primary color border
- **Action**: Opens activity tracking with "Run" pre-selected
- **Navigation**: Routes to `/active?type=run`
- **Use Case**: Quick access to start tracking a running session
- **Visual**: Full-width, outlined button

#### 3. Record a Walk (Secondary Button)
- **Style**: Outlined button with primary color border
- **Action**: Opens activity tracking with "Walk" pre-selected
- **Navigation**: Routes to `/active?type=walk`
- **Use Case**: Quick access to start tracking a walking session
- **Visual**: Full-width, outlined button

#### 4. Map Missions (Secondary Button)
- **Style**: Outlined button with map icon
- **Action**: Opens the Map Missions feature
- **Navigation**: Routes to `/mission`
- **Use Case**: Access location-based fitness challenges and missions
- **Visual**: Full-width, outlined button with icon
- **Icon**: Map outline icon

### Button Hierarchy
- **Primary**: Start a Workout (most prominent)
- **Secondary**: Log a Run, Record a Walk, Map Missions (equal importance)

---

## 3. Recent Activity Section - Your Recent Activity

### Purpose
Displays a chronological list of your recently completed workouts and activities.

### Activity Card Components

Each activity card shows:

#### Visual Elements
- **Activity Icon**: Type-specific icon in a colored rounded container
- **Activity Name**: Bold title of the workout (e.g., "Morning Run")
- **Activity Details**: Summary information (e.g., "3.2 km • 25 min • 180 cal")
- **Date Label**: When the activity occurred (e.g., "Today", "Yesterday", "2 days ago")

#### Activity Type Mappings

| Activity Type | Icon | Color |
|--------------|------|-------|
| Run | Running icon | Primary (Blue) |
| Walk | Walking icon | Green (#10B981) |
| Workout | Dumbbells icon | Red/Error |
| Cycle | Bicycle icon | Purple (#9333EA) |

### Interactions
- **Tap Activity Card**: Opens detailed view of that specific activity
- **Navigation**: Routes to `/activity/{activityId}`

### States

#### Empty State
- **Display**: When no activities have been logged today
- **Message**: "No activity yet today" with "Let's get started!" subtitle
- **Icon**: Fitness center icon in muted color
- **Purpose**: Encourages user to start their first activity

#### Loading State
- **Display**: Skeleton placeholders for 3 activity cards
- **Animation**: Subtle shimmer effect (optional)
- **Purpose**: Provides visual feedback while data loads

#### Error State
- **Display**: Error icon with message
- **Message**: "Failed to load activities" with "Pull to refresh" instruction
- **Icon**: Error outline icon in error color
- **Action**: User can pull down to retry loading

### Data Source
Activities are fetched from the `recentActivitiesProvider` which retrieves:
- Recent workout sessions
- Tracked runs and walks
- Cycling activities
- Other logged exercises

---

## Map Missions Feature

### Overview
The Map Missions feature (accessed via the "Map Missions" button) provides location-based fitness challenges and gamified workout experiences.

### Expected Functionality
While the implementation details are pending, the Map Missions feature is designed to:

1. **Location-Based Challenges**
   - Discover fitness missions in your area
   - Complete challenges at specific locations
   - Unlock achievements based on geographic exploration

2. **Mission Types**
   - Distance-based missions (e.g., "Run 5km in Central Park")
   - Location discovery missions (e.g., "Visit 3 fitness landmarks")
   - Time-based challenges (e.g., "Complete workout within 30 minutes")

3. **Map Interface**
   - Interactive map showing available missions
   - Current location tracking
   - Mission markers and waypoints
   - Route visualization

4. **Progress Tracking**
   - Mission completion status
   - Rewards and badges earned
   - Leaderboards (optional)
   - Personal mission history

### Navigation
- **Access**: Tap "Map Missions" button in CTA Section
- **Route**: `/mission`
- **Return**: Back button returns to Track Tab

---

## User Interactions

### Pull to Refresh
- **Gesture**: Swipe down from the top of the screen
- **Action**: Refreshes all data providers
- **Feedback**: Loading spinner appears during refresh
- **Updates**: 
  - Daily stats (steps, calories, active minutes)
  - Recent activities list

### Navigation Flow

```
Track Tab
├── Start a Workout → Workout Selection Screen (/active)
├── Log a Run → Activity Tracking (Run) (/active?type=run)
├── Record a Walk → Activity Tracking (Walk) (/active?type=walk)
├── Map Missions → Map Missions Screen (/mission)
└── Activity Card → Activity Details (/activity/{id})
```

---

## Header Section

### App Branding
- **Title**: "FlowFit" displayed in bold
- **Position**: Top-left of the screen

### Notification Bell
- **Icon**: Bell icon
- **Position**: Top-right of the screen
- **Badge**: Shows unread notification count
  - Displays exact count (1-9)
  - Displays "9+" for counts greater than 9
  - Hidden when count is 0
- **Action**: Taps opens notifications screen (when implemented)
- **Color**: Badge uses error color (red) for visibility

---

## Design Specifications

### Layout
- **Padding**: 16px horizontal padding for all sections
- **Spacing**: 24px vertical spacing between sections
- **Card Radius**: 16px border radius for all cards
- **Shadow**: Subtle elevation with 0.05 opacity black shadow

### Typography
- **Section Headers**: Title Large, Bold weight
- **Card Titles**: Title Medium, Semi-bold weight
- **Card Values**: Headline Medium, Bold weight
- **Card Labels**: Body Small, Regular weight
- **Button Text**: Title Medium, Semi-bold weight

### Colors
- **Primary**: Used for steps, primary buttons, run activities
- **Error/Red**: Used for calories, workout activities
- **Tertiary**: Used for active minutes
- **Green (#10B981)**: Used for walk activities
- **Purple (#9333EA)**: Used for cycle activities
- **Surface**: Card backgrounds
- **Background**: Page background

### Accessibility
- **Touch Targets**: Minimum 48x48 dp for all interactive elements
- **Contrast**: WCAG AA compliant color contrast ratios
- **Icons**: Meaningful icons with proper semantic labels
- **Tooltips**: Available on navigation items

---

## Technical Implementation

### State Management
- **Provider**: Uses Riverpod for state management
- **Async Data**: AsyncValue for handling loading/error/data states
- **Refresh**: Manual refresh invalidates providers

### Data Models

#### DailyStats
```dart
{
  steps: int,
  stepsGoal: int,
  stepsProgress: double (0.0 - 1.0),
  calories: int,
  activeMinutes: int
}
```

#### RecentActivity
```dart
{
  id: String,
  type: String ('run' | 'walk' | 'workout' | 'cycle'),
  name: String,
  details: String,
  dateLabel: String
}
```

### Navigation
- **Router**: Uses GoRouter for navigation
- **Routes**: Declarative routing with path parameters
- **Query Params**: Supports pre-selection via query parameters

---

## Best Practices for Users

### Daily Usage
1. **Morning Check**: Review your daily goals in the Stats Section
2. **Start Activity**: Use CTA buttons to begin your workout
3. **Track Progress**: Monitor stats throughout the day
4. **Review History**: Check Recent Activity to see your accomplishments

### Goal Achievement
- **Steps**: Aim to reach 100% of your daily step goal
- **Calories**: Track calorie burn to meet fitness objectives
- **Active Minutes**: Accumulate recommended active time daily
- **Consistency**: Build streaks by logging activities regularly

### Troubleshooting
- **Stats Not Updating**: Pull down to refresh
- **Missing Activities**: Check if activity was properly saved
- **Sync Issues**: Ensure device permissions are granted
- **Loading Errors**: Check internet connection and retry

---

## Future Enhancements

### Planned Features
- **Weekly/Monthly Views**: Toggle between different time periods
- **Goal Customization**: Adjust daily targets from this screen
- **Activity Filters**: Filter recent activities by type
- **Quick Stats**: Swipeable cards for additional metrics
- **Social Sharing**: Share achievements directly from cards
- **Workout Recommendations**: AI-suggested workouts based on history

### Map Missions Expansion
- **Multiplayer Missions**: Compete with friends
- **Seasonal Events**: Limited-time location challenges
- **AR Integration**: Augmented reality mission experiences
- **Route Planning**: Create custom mission routes

---

## Summary

The Track Tab serves as your fitness command center, providing:
- **Real-time monitoring** of daily fitness metrics
- **Quick access** to start various types of workouts
- **Historical view** of recent activities
- **Gamified experiences** through Map Missions
- **Intuitive navigation** to detailed tracking screens

This page is designed to keep you motivated, informed, and ready to achieve your fitness goals every day.
