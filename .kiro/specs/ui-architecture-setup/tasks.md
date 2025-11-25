# Implementation Plan

- [x] 1. Set up core architecture and folder structure





  - Create domain, data, and presentation layer directories
  - Set up Riverpod code generation configuration
  - Configure go_router for navigation
  - Add required dependencies to pubspec.yaml
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2. Define domain entities and repository interfaces



  - [x] 2.1 Create core domain entities


    - Implement UserProfile entity
    - Implement Workout entity with WorkoutType enum
    - Implement HeartRatePoint entity
    - _Requirements: 2.2_
  

  - [x] 2.2 Create fitness domain entities





    - Implement WorkoutRepository interface
    - Implement HeartRateRepository interface
    - _Requirements: 3.1, 6.1, 6.2, 7.1_
  

  - [x] 2.3 Create nutrition domain entities





    - Implement FoodLog entity
    - Implement Macros entity
    - Implement NutritionRepository interface
    - _Requirements: 3.1, 8.1, 8.2_
  

  - [ ] 2.4 Create sleep domain entities





    - Implement SleepSession entity
    - Implement SleepRepository interface
    - _Requirements: 3.1, 9.1, 9.2_
  
  - [x] 2.5 Create mood domain entities


    - Implement MoodEntry entity
    - Implement MoodRepository interface
    - _Requirements: 3.1, 12.1, 12.2_
  

  - [x] 2.6 Create profile domain entities

    - Implement Streak entity
    - Implement ProfileRepository interface
    - _Requirements: 3.1, 11.1, 13.1_

- [ ] 3. Implement mock repositories with sample data
  - [ ] 3.1 Implement MockWorkoutRepository
    - Generate 15 sample workouts with realistic data
    - Implement getWorkoutHistory method
    - Implement getWorkoutById method
    - Implement saveWorkout method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 6.1, 6.2_
  
  - [ ] 3.2 Implement MockHeartRateRepository
    - Integrate with existing WatchBridgeService
    - Implement getHeartRateStream using watch bridge
    - Generate mock historical heart rate data
    - Implement saveHeartRateData method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 5.1, 5.2, 14.2, 14.4_
  
  - [ ] 3.3 Implement MockNutritionRepository
    - Generate sample food logs with accurate macros
    - Implement getFoodLogsForDate method
    - Implement addFoodLog method
    - Implement getDailySummary method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 8.1, 8.3_
  
  - [ ] 3.4 Implement MockSleepRepository
    - Generate 7 days of sample sleep sessions
    - Implement getSleepSessions method
    - Implement saveSleepSession method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 9.1, 9.2_
  
  - [ ] 3.5 Implement MockMoodRepository
    - Generate sample mood entries over time
    - Implement getMoodEntries method
    - Implement addMoodEntry method
    - Implement getRecommendationsForMood method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 12.1, 12.2_
  
  - [ ] 3.6 Implement MockProfileRepository
    - Generate sample user profile
    - Generate sample streak data
    - Implement getUserProfile method
    - Implement getUserStreaks method
    - Add TODO comments for Supabase integration
    - _Requirements: 3.2, 3.3, 3.4, 11.1, 13.1_
  
  - [ ]*  3.7 Write property test for mock repositories
    - **Property 3: Mock repositories return valid data**
    - **Validates: Requirements 3.2, 3.3**

- [ ] 4. Set up Riverpod providers
  - [ ] 4.1 Create repository providers
    - Implement workoutRepositoryProvider
    - Implement heartRateRepositoryProvider
    - Implement nutritionRepositoryProvider
    - Implement sleepRepositoryProvider
    - Implement moodRepositoryProvider
    - Implement profileRepositoryProvider
    - _Requirements: 4.1, 4.2_
  
  - [ ] 4.2 Create service providers
    - Implement watchBridgeServiceProvider
    - Add disposal logic for watch bridge
    - _Requirements: 4.1, 14.1, 14.3_
  
  - [ ] 4.3 Create state providers
    - Implement heartRateStreamProvider
    - Implement workoutListProvider
    - Implement activeWorkoutNotifierProvider
    - Implement nutritionSummaryProvider
    - Implement sleepHistoryProvider
    - Implement moodHistoryProvider
    - Implement streakProvider
    - _Requirements: 4.3, 4.4, 4.5_

- [ ] 5. Implement navigation and routing
  - [ ] 5.1 Configure go_router
    - Define all route paths
    - Set up nested routes for features
    - Configure route parameters
    - _Requirements: 1.1, 1.2, 1.4_
  
  - [ ] 5.2 Create bottom navigation widget
    - Implement AppBottomNavigation widget
    - Add navigation items for Home, Fitness, Reports, More
    - Handle route-based active state
    - _Requirements: 1.1, 1.4_
  
  - [ ]*  5.3 Write property test for navigation
    - **Property 1: Navigation transitions work correctly**
    - **Validates: Requirements 1.2, 1.5**

- [ ] 6. Create shared UI components
  - [ ] 6.1 Create card components
    - Implement StatCard widget
    - Implement ChartCard widget
    - Implement WorkoutCard widget
    - Implement FoodLogCard widget
    - Implement SleepSessionCard widget
    - _Requirements: 1.3, 6.2, 8.4, 9.2_
  
  - [ ] 6.2 Create state components
    - Implement EmptyStateView widget
    - Implement ErrorView widget with retry
    - Implement LoadingIndicator widget
    - _Requirements: 1.3, 6.5_
  
  - [ ] 6.3 Create heart rate components
    - Implement LiveHeartRateWidget
    - Implement ConnectionStatusBadge
    - Add real-time update handling
    - _Requirements: 5.3, 5.4, 5.5_
  
  - [ ] 6.4 Create streak components
    - Implement StreakCalendar widget
    - Implement StreakBadge widget
    - Implement MilestoneNotification widget
    - _Requirements: 13.2, 13.3_
  
  - [ ] 6.5 Create mood components
    - Implement MoodSelector widget
    - Implement MoodCard widget
    - _Requirements: 12.1_

- [ ] 7. Implement dashboard screen
  - [ ] 7.1 Create dashboard layout
    - Implement DashboardScreen widget
    - Add quick stats overview section
    - Add navigation shortcuts to features
    - _Requirements: 1.1, 1.3_
  
  - [ ] 7.2 Integrate live heart rate display
    - Connect to heartRateStreamProvider
    - Display current BPM value
    - Show connection status indicator
    - Handle disconnected state
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 7.3 Add streak display
    - Show current workout streak
    - Display recent activity calendar
    - _Requirements: 13.1, 13.2_
  
  - [ ]*  7.4 Write property test for heart rate flow
    - **Property 4: Heart rate data flows from watch to phone**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 14.2, 14.4**
  
  - [ ]*  7.5 Write unit tests for dashboard
    - Test dashboard renders without errors
    - Test heart rate display updates
    - Test connection status indicator

- [ ] 8. Checkpoint - Verify core architecture
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement fitness feature screens
  - [ ] 9.1 Create workout history screen
    - Implement WorkoutHistoryScreen widget
    - Display list of past workouts
    - Show workout type, duration, distance, calories
    - Handle empty state
    - _Requirements: 6.1, 6.2, 6.5_
  
  - [ ] 9.2 Create workout detail screen
    - Implement WorkoutDetailScreen widget
    - Display comprehensive workout metrics
    - Show heart rate data chart
    - Add pace and route placeholders
    - Handle navigation from history list
    - _Requirements: 6.3, 6.4_
  
  - [ ] 9.3 Create workout session screen
    - Implement WorkoutSessionScreen widget
    - Add workout timer display
    - Show live metrics (time, distance, heart rate)
    - Implement start/pause/stop controls
    - _Requirements: 7.1, 7.2, 7.5_
  
  - [ ] 9.4 Create workout summary screen
    - Implement WorkoutSummaryScreen widget
    - Display total statistics
    - Show workout completion message
    - _Requirements: 7.4_
  
  - [ ]*  9.5 Write property test for workout display
    - **Property 5: Workout display completeness**
    - **Validates: Requirements 6.2, 6.3, 6.4**
  
  - [ ]*  9.6 Write property test for active workout
    - **Property 6: Active workout displays live metrics**
    - **Validates: Requirements 7.2, 7.3, 7.5**
  
  - [ ]*  9.7 Write unit tests for fitness screens
    - Test workout history list rendering
    - Test workout detail navigation
    - Test workout session controls
    - Test pause preserves metrics

- [ ] 10. Implement nutrition feature screens
  - [ ] 10.1 Create nutrition dashboard screen
    - Implement NutritionScreen widget
    - Display daily calorie summary
    - Show macro breakdown (carbs, protein, fat)
    - Add progress indicators for goals
    - _Requirements: 8.1, 8.3, 8.5_
  
  - [ ] 10.2 Create food logging screen
    - Implement FoodLogScreen widget
    - Add input fields for food name, calories, macros
    - Implement meal type selection
    - Add form validation
    - _Requirements: 8.2_
  
  - [ ] 10.3 Create food history view
    - Display list of logged meals
    - Show timestamps for each entry
    - Group by meal type
    - _Requirements: 8.4_
  
  - [ ]*  10.4 Write property test for nutrition display
    - **Property 7: Nutrition data aggregation and display**
    - **Validates: Requirements 8.3, 8.4, 8.5**
  
  - [ ]*  10.5 Write unit tests for nutrition screens
    - Test daily summary calculations
    - Test food log form validation
    - Test progress indicators

- [ ] 11. Implement sleep feature screens
  - [ ] 11.1 Create sleep tracking screen
    - Implement SleepScreen widget
    - Display sleep history list
    - Show duration and quality for each session
    - _Requirements: 9.1, 9.2_
  
  - [ ] 11.2 Create sleep detail screen
    - Implement SleepDetailScreen widget
    - Display sleep stages visualization
    - Show interruption count
    - Add quality rating display
    - _Requirements: 9.4_
  
  - [ ] 11.3 Create sleep logging screen
    - Implement SleepLogScreen widget
    - Add inputs for start time, end time, quality
    - Implement form validation
    - _Requirements: 9.3_
  
  - [ ] 11.4 Add calendar navigation
    - Implement calendar view for sleep data
    - Handle multi-day navigation
    - _Requirements: 9.5_
  
  - [ ]*  11.5 Write property test for sleep display
    - **Property 8: Sleep session display completeness**
    - **Validates: Requirements 9.2, 9.4**
  
  - [ ]*  11.6 Write unit tests for sleep screens
    - Test sleep history rendering
    - Test sleep detail display
    - Test calendar navigation

- [ ] 12. Checkpoint - Verify feature screens
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Implement mood feature screens
  - [ ] 13.1 Create mood logging screen
    - Implement MoodLogScreen widget
    - Add mood selector interface
    - Implement notes input
    - _Requirements: 12.1_
  
  - [ ] 13.2 Create mood history screen
    - Display list of mood entries
    - Show timestamps for each entry
    - _Requirements: 12.3_
  
  - [ ] 13.3 Create mood recommendations screen
    - Implement MoodRecommendationsScreen widget
    - Display filtered workout recommendations
    - Filter by intensity and type based on mood
    - _Requirements: 12.2, 12.4_
  
  - [ ]*  13.4 Write property test for mood recommendations
    - **Property 10: Mood-based workout recommendations**
    - **Validates: Requirements 12.2, 12.4**
  
  - [ ]*  13.5 Write property test for mood history
    - **Property 11: Mood history display**
    - **Validates: Requirements 12.3, 12.5**
  
  - [ ]*  13.6 Write unit tests for mood screens
    - Test mood selector interaction
    - Test recommendation filtering
    - Test mood history display

- [ ] 14. Implement reports and analytics screens
  - [ ] 14.1 Create reports dashboard
    - Implement ReportsScreen widget
    - Add navigation to report types
    - Display AI coaching placeholder
    - _Requirements: 10.1, 10.5_
  
  - [ ] 14.2 Create cardio report screen
    - Implement CardioReportScreen widget
    - Add heart rate trend chart
    - Add workout frequency chart
    - Add intensity distribution chart
    - _Requirements: 10.2_
  
  - [ ] 14.3 Create strength report screen
    - Implement StrengthReportScreen widget
    - Add exercise volume chart
    - Add progression chart
    - Add muscle group distribution chart
    - _Requirements: 10.3_
  
  - [ ] 14.4 Create nutrition report screen
    - Implement NutritionReportScreen widget
    - Add calorie trend chart
    - Add macro distribution chart
    - Add mood trend integration
    - _Requirements: 10.4, 12.5_
  
  - [ ]*  14.5 Write property test for report charts
    - **Property 14: Report chart completeness**
    - **Validates: Requirements 10.2, 10.3, 10.4**
  
  - [ ]*  14.6 Write unit tests for report screens
    - Test chart rendering
    - Test data visualization
    - Test empty state handling

- [ ] 15. Implement profile and settings screens
  - [ ] 15.1 Create profile screen
    - Implement ProfileScreen widget
    - Display username, profile photo, personal info
    - Show email, date of birth, sex, location
    - Add weight tracking section
    - _Requirements: 11.1, 11.2, 11.5_
  
  - [ ] 15.2 Create settings screen
    - Implement SettingsScreen widget
    - Add fitness notification toggle
    - Add Health Connect integration toggle
    - Add privacy policy link
    - _Requirements: 11.3_
  
  - [ ] 15.3 Create account management screen
    - Implement AccountScreen widget
    - Add change password option
    - Add delete account option
    - Add logout option
    - _Requirements: 11.4_
  
  - [ ] 15.4 Create streaks screen
    - Implement StreaksScreen widget
    - Display workout streak calendar
    - Display nutrition logging streak
    - Display app usage streak
    - Show achievement badges
    - Show empathetic messaging for broken streaks
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ]*  15.5 Write property test for profile display
    - **Property 9: Profile display completeness**
    - **Validates: Requirements 11.2, 11.5**
  
  - [ ]*  15.6 Write property test for streak tracking
    - **Property 12: Streak tracking and display**
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.5**
  
  - [ ]*  15.7 Write property test for streak empathy
    - **Property 13: Streak break empathy**
    - **Validates: Requirements 13.4**
  
  - [ ]*  15.8 Write unit tests for profile screens
    - Test profile data display
    - Test settings toggles
    - Test streak calculations
    - Test milestone badges

- [ ] 16. Implement theme and styling
  - [ ] 16.1 Create app theme
    - Define light theme with Material 3
    - Define dark theme with Material 3
    - Configure color schemes
    - Set up typography
    - _Requirements: 1.3_
  
  - [ ] 16.2 Apply consistent styling
    - Style all card components
    - Style all form inputs
    - Style all buttons
    - Add consistent spacing and padding
    - _Requirements: 1.3_

- [ ] 17. Add error handling and edge cases
  - [ ] 17.1 Implement error handling in repositories
    - Add RepositoryException class
    - Handle timeout errors
    - Handle validation errors
    - Add error logging
    - _Requirements: 1.3_
  
  - [ ] 17.2 Implement error handling in UI
    - Add error boundaries
    - Display user-friendly error messages
    - Add retry functionality
    - Handle loading states
    - _Requirements: 1.3, 5.5, 6.5_
  
  - [ ] 17.3 Handle watch connection errors
    - Display connection status
    - Show reconnection guidance
    - Handle permission errors
    - _Requirements: 5.5, 14.2_

- [ ] 18. Final checkpoint - Complete testing
  - Ensure all tests pass, ask the user if questions arise.

- [ ]*  19. Write property test for feature screen rendering
  - **Property 2: All feature screens display mock data**
  - **Validates: Requirements 1.3**

- [ ] 20. Polish and refinement
  - [ ] 20.1 Add animations and transitions
    - Add page transition animations
    - Add loading animations
    - Add success feedback animations
    - _Requirements: 1.3_
  
  - [ ] 20.2 Optimize performance
    - Add list view optimizations
    - Implement lazy loading where appropriate
    - Optimize chart rendering
    - _Requirements: 1.3_
  
  - [ ] 20.3 Final review and documentation
    - Review all TODO comments for backend integration
    - Verify all screens are navigable
    - Verify mock data is realistic
    - Ensure Watch Bridge is preserved and functional
    - _Requirements: 3.4, 14.1, 15.1, 15.2, 15.3, 15.4, 15.5_
