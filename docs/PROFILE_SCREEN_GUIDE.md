# Profile Screen Implementation Guide

## Overview

The Profile Screen provides users with access to their personal information, statistics, settings, and account management features including sign-out functionality.

## Features

### 1. Profile Header
- **Profile Picture**: Circular avatar with edit button
- **User Name**: Display name (e.g., "Alex Taylor")
- **Join Date**: Account creation date (e.g., "Joined March 2025")

### 2. Statistics Cards
Three key metrics displayed in a row:
- **Workouts**: Total number of completed workouts (128)
- **Streak**: Current consecutive days of activity (15)
- **Awards**: Total achievements earned (5)

### 3. Settings Options
Four main settings categories with navigation:

#### Personal Information
- Icon: User icon (blue)
- View and edit user profile details
- Fields: Name, Email, Phone, Date of Birth, Height, Weight

#### Notifications
- Icon: Bell icon (light blue)
- Manage notification preferences
- Options:
  - Workout Reminders
  - Heart Rate Alerts
  - Sleep Reminders
  - Nutrition Reminders
  - Achievement Notifications

#### Security
- Icon: Shield icon (orange)
- Account security settings
- Options:
  - Change Password
  - Two-Factor Authentication
  - Connected Devices
  - Login History

#### Help & Support
- Icon: Question mark icon (green)
- Access help resources
- Options:
  - User Guide
  - FAQs
  - Contact Support
  - Terms of Service
  - Privacy Policy
  - App Version Info

### 4. Log Out Button
- Prominent red button at the bottom
- Confirmation dialog before logging out
- Redirects to welcome screen after logout

## Implementation

### File Structure
```
lib/screens/phone/
├── profile_screen.dart          # Main profile screen
├── example_navigation.dart      # Navigation examples
```

### Navigation Setup

The profile screen is registered in `lib/main.dart`:

```dart
routes: {
  // ... other routes
  '/profile': (context) => const ProfileScreen(),
}
```

### Usage Examples

#### 1. Navigate from AppBar
```dart
AppBar(
  title: const Text('FlowFit'),
  actions: [
    IconButton(
      icon: const Icon(SolarIconsOutline.user),
      onPressed: () {
        Navigator.pushNamed(context, '/profile');
      },
    ),
  ],
)
```

#### 2. Navigate from Bottom Navigation
```dart
BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(
      icon: Icon(SolarIconsOutline.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(SolarIconsOutline.user),
      label: 'Profile',
    ),
  ],
  onTap: (index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  },
)
```

#### 3. Navigate from Button
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.pushNamed(context, '/profile');
  },
  icon: const Icon(SolarIconsBold.user),
  label: const Text('View Profile'),
)
```

## Design Specifications

### Colors (from AppTheme)
- **Primary Blue**: `#3B82F6` - Main actions and icons
- **Light Blue**: `#5DADE2` - Secondary elements
- **Cyan**: `#5DD9E2` - Tertiary accents
- **Red**: For logout button and destructive actions

### Typography
- **Font Family**: General Sans
- **Profile Name**: `headlineMedium` (28px, bold)
- **Section Titles**: `titleMedium` (16px, w600)
- **Body Text**: `bodyMedium` (14px, normal)
- **Labels**: `bodySmall` (12px, normal)

### Spacing
- **Card Padding**: 16px
- **Section Spacing**: 24px
- **Item Spacing**: 12px
- **Icon Size**: 24px (settings), 48px (containers)

### Border Radius
- **Cards**: 16px
- **Icon Containers**: 12px
- **Buttons**: 16px

## Integration with FlowFit

### Current Device Information
Based on the README.md:

**Watch Device (SM_R930)**
- Model: Galaxy Watch (SM_R930)
- Device ID: `adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- Platform: Wear OS powered by Samsung
- Run Command: `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart`

**Phone Device (22101320G)**
- Model: Android Phone (22101320G)
- Device ID: `6ece264d`
- Run Command: `flutter run -d 6ece264d -t lib/main.dart`

### Authentication Integration

To implement actual sign-out functionality, integrate with your auth service:

```dart
// In profile_screen.dart, update the log out button:
if (confirm == true && context.mounted) {
  // Sign out from Supabase
  await Supabase.instance.client.auth.signOut();
  
  // Clear local data
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  // Navigate to welcome screen
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/welcome',
    (route) => false,
  );
}
```

### Data Persistence

User profile data should be stored in:
1. **Supabase**: Cloud storage for sync across devices
2. **Local SQLite**: Offline access via `sqflite`
3. **SharedPreferences**: Quick access to user settings

Example profile data model:
```dart
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final DateTime joinDate;
  final int totalWorkouts;
  final int currentStreak;
  final int totalAwards;
  
  // ... constructor and methods
}
```

## Testing

### Manual Testing Checklist
- [ ] Profile screen loads correctly
- [ ] User information displays properly
- [ ] Statistics show correct values
- [ ] All settings options are tappable
- [ ] Navigation to sub-screens works
- [ ] Log out button shows confirmation dialog
- [ ] Log out redirects to welcome screen
- [ ] Back button navigation works correctly
- [ ] Theme (light/dark) applies correctly
- [ ] Icons render properly

### Test on Devices
```bash
# Test on phone
flutter run -d 6ece264d -t lib/main.dart

# Navigate to profile:
# 1. From home screen, tap profile icon
# 2. Or use: Navigator.pushNamed(context, '/profile')
```

## Future Enhancements

### Planned Features
1. **Profile Picture Upload**: Allow users to upload custom profile pictures
2. **Edit Profile**: In-place editing of user information
3. **Statistics Charts**: Visual representation of workout history
4. **Achievement Badges**: Display earned badges and awards
5. **Social Features**: Friends list and activity sharing
6. **Theme Selector**: Choose between light/dark/auto themes
7. **Language Settings**: Multi-language support
8. **Data Export**: Export health data to CSV/JSON
9. **Account Deletion**: Self-service account deletion

### Integration Points
- **Supabase Auth**: User authentication and session management
- **Supabase Storage**: Profile picture storage
- **Supabase Database**: User profile and settings data
- **Watch Sync**: Sync profile settings to Galaxy Watch
- **Samsung Health**: Import user data from Samsung Health

## Troubleshooting

### Common Issues

**Profile screen not loading**
- Check route is registered in `main.dart`
- Verify import statement is correct
- Check for compilation errors

**Navigation not working**
- Ensure context is valid
- Check route name matches exactly
- Verify MaterialApp has routes defined

**Icons not displaying**
- Confirm `solar_icons` package is installed
- Check import: `import 'package:solar_icons/solar_icons.dart';`
- Run `flutter pub get`

**Theme not applying**
- Verify `AppTheme` is imported
- Check `MaterialApp` has theme defined
- Ensure using `Theme.of(context)` for colors

## Resources

- **Design Reference**: Profile screen mockup (provided image)
- **Icons**: Solar Icons package
- **Theme**: `lib/theme/app_theme.dart`
- **Navigation**: Flutter named routes
- **State Management**: Flutter Riverpod (for future enhancements)

## Support

For questions or issues:
1. Check this guide
2. Review `lib/screens/phone/example_navigation.dart`
3. Check main README.md
4. Review Flutter documentation
5. Check project issues on GitHub
