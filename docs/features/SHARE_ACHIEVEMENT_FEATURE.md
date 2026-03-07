# Share Achievement Feature - Strava Style

## Summary
Added a Strava-style share achievement feature that allows users to create beautiful shareable images of their workout with GPS route overlay and custom background images.

## Features

### 1. Running Summary Screen Updates

**Save to History:**
- Backend calls commented out (ready for later)
- Shows success message
- Navigates back to dashboard (Track tab)
- Timer resets for next workout

**Share Achievement Button:**
- Opens new share achievement screen
- Passes session data

### 2. Share Achievement Screen (NEW)

**Strava-Style Card:**
- 400x700 shareable image
- Background options:
  - Default gradient (blue to purple)
  - Custom image from gallery
- White text overlay with stats
- GPS route map with orange polyline
- Pulsify branding at bottom

**Stats Displayed:**
- Distance (km)
- Pace (min/km)
- Time (MM:SS)
- GPS route visualization

**User Flow:**
1. Complete workout → Summary screen
2. Tap "Share Achievement"
3. (Optional) Add background image from gallery
4. Tap "Share" to generate image
5. Share to social media
6. Auto-navigate back to dashboard

## Technical Implementation

### Share Achievement Screen

**Image Generation:**
```dart
RepaintBoundary + RenderRepaintBoundary
→ Captures widget as PNG image
→ Saves to temporary file
→ Shares via Share Plus plugin
```

**Background Image:**
```dart
ImagePicker → Gallery selection
→ Displays as background
→ Dark overlay for text readability
```

**GPS Route Map:**
```dart
FlutterMap with interaction disabled
→ Shows route polyline (orange with white border)
→ Fits in 300px container
→ Rounded corners with white border
```

### Components

**Shareable Card Structure:**
1. Background layer (image or gradient)
2. Dark gradient overlay (30-70% opacity)
3. Stats at top (Distance, Pace, Time)
4. GPS route map in center
5. Pulsify branding at bottom

**Controls:**
- "Add Background Image" button
- "Share Achievement" button
- Loading state during generation

## User Experience

### Complete Flow:
1. **Start Workout** → Mood check → Setup → Active running
2. **End Workout** → Summary screen shows:
   - Mood transformation
   - All metrics
   - Route map
   - Two buttons: "Save to History" & "Share Achievement"

3. **Save to History:**
   - Shows success message
   - Returns to dashboard
   - Ready for next workout

4. **Share Achievement:**
   - Opens share screen
   - Default gradient background
   - Can add custom image
   - Generates shareable image
   - Shares to social media
   - Returns to dashboard

## Visual Design

### Shareable Card:
```
┌─────────────────────────┐
│  Distance: 6.05 km      │ ← White text
│  Pace: 8:00 /km         │
│  Time: 48m 24s          │
│                         │
│  ┌─────────────────┐    │
│  │                 │    │
│  │   GPS Route     │    │ ← Orange polyline
│  │   (Map)         │    │   on map
│  │                 │    │
│  └─────────────────┘    │
│                         │
│  🔥 Pulsify             │ ← Branding
└─────────────────────────┘
```

### Background Options:
- **Default**: Blue-purple gradient
- **Custom**: User's photo from gallery
- **Overlay**: Dark gradient for readability

### Route Styling:
- **Polyline**: 5px width, orange (#FF6B35)
- **Border**: 2px white outline
- **Container**: White 3px border, rounded corners

## Dependencies Used

- `image_picker`: Select background images
- `share_plus`: Share generated images
- `flutter_map`: Display GPS route
- `path_provider`: Temporary file storage
- `dart:ui`: Image rendering

## Code Structure

```
lib/screens/workout/running/
├── running_setup_screen.dart
├── active_running_screen.dart
├── running_summary_screen.dart
└── share_achievement_screen.dart  ← NEW
```

## Navigation Flow

```
Track Tab
  ↓
Start Workout (Mood Check)
  ↓
Workout Type Selection
  ↓
Running Setup
  ↓
Active Running (Strava-style map)
  ↓
Running Summary
  ├→ Save to History → Dashboard
  └→ Share Achievement
       ├→ Add Image (optional)
       └→ Share → Dashboard
```

## Future Enhancements

1. **More Background Options:**
   - Preset gradient themes
   - Blur effects
   - Filters

2. **Additional Stats:**
   - Heart rate zones
   - Elevation gain
   - Split times

3. **Customization:**
   - Text color options
   - Font styles
   - Logo placement

4. **Social Integration:**
   - Direct Instagram/Facebook sharing
   - Story format (9:16)
   - Hashtag suggestions

5. **Templates:**
   - Multiple card layouts
   - Seasonal themes
   - Achievement badges

## Testing

### To Test:
1. Complete a running workout
2. On summary screen, tap "Share Achievement"
3. See default gradient background with stats
4. Tap "Add Background Image"
5. Select image from gallery
6. See image as background with overlay
7. Tap "Share Achievement"
8. Wait for image generation
9. Share dialog appears
10. After sharing, returns to dashboard

### Expected Output:
- High-quality PNG image (3x pixel ratio)
- All stats clearly visible
- GPS route displayed correctly
- Pulsify branding present
- Shareable on all social platforms
