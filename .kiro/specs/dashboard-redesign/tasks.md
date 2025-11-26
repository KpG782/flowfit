# Implementation Plan

- [x] 1. Set up data models and providers





  - Create DailyStats and RecentActivity data models with computed properties
  - Implement dashboard_providers.dart with all Riverpod providers
  - Set up provider structure for state management
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ]* 1.1 Write property test for date label formatting
  - **Property 3: Date label formatting correctness**
  - **Validates: Requirements 4.3, 4.4, 4.5**

- [x] 2. Implement HomeHeader widget





  - Create HomeHeader widget with app branding
  - Add notification bell icon with Solar Icons
  - Implement notification badge with count display
  - Handle badge formatting (9+ for counts > 9)
  - Add navigation to notifications screen
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ]* 2.1 Write property test for notification badge formatting
  - **Property 11: Notification badge formatting**
  - **Validates: Requirements 7.2, 7.3, 7.4**

- [x] 3. Implement StatsSection widget and stat cards





  - Create StatsSection widget with section header
  - Implement StepsCard with progress bar
  - Implement CompactStatsCard for calories and active time
  - Add two-column grid layout for compact cards
  - Implement loading skeleton placeholders
  - Implement error state UI
  - Wire up dailyStatsProvider
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 9.1_

- [ ]* 3.1 Write property test for stats display completeness
  - **Property 1: Stats card information completeness**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [ ]* 3.2 Write property test for card styling consistency
  - **Property 7: Card styling consistency**
  - **Validates: Requirements 6.3, 6.4, 6.5, 6.8**

- [ ]* 3.3 Write property test for provider loading state handling
  - **Property 12: Provider loading state handling**
  - **Validates: Requirements 2.6, 5.6**

- [ ]* 3.4 Write property test for provider error state handling
  - **Property 13: Provider error state handling**
  - **Validates: Requirements 2.7, 5.7**

- [x] 4. Implement CTASection widget





  - Create CTASection widget with section header
  - Implement "Start a Workout" primary button
  - Implement "Log a Run" outlined button
  - Implement "Record a Walk" outlined button
  - Add navigation routing for all buttons
  - Pass activity type parameters for run/walk buttons
  - Apply theme styling to buttons
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 9.2_

- [ ]* 4.1 Write property test for navigation with correct parameters
  - **Property 4: Navigation with correct parameters**
  - **Validates: Requirements 3.4, 3.5, 3.6**

- [ ]* 4.2 Write property test for button sizing consistency
  - **Property 10: Button sizing consistency**
  - **Validates: Requirements 6.6**
-

- [x] 5. Implement RecentActivitySection widget and activity cards






  - Create RecentActivitySection widget with section header
  - Implement ActivityCard widget
  - Add activity type to icon mapping (run, walk, workout, cycle)
  - Add activity type to color mapping
  - Implement activity list rendering
  - Add navigation to activity details on card tap
  - Implement empty state UI
  - Implement loading skeleton placeholders
  - Implement error state UI
  - Wire up recentActivitiesProvider
  - _Requirements: 4.1, 4.2, 4.6, 4.7, 4.8, 9.3_

- [ ]* 5.1 Write property test for activity display completeness
  - **Property 2: Activity information completeness**
  - **Validates: Requirements 4.2**

- [ ]* 5.2 Write property test for activity card navigation
  - **Property 5: Activity card navigation**
  - **Validates: Requirements 4.6**

- [ ]* 5.3 Write property test for activity type visual consistency
  - **Property 6: Activity type visual consistency**
  - **Validates: Requirements 4.8**

- [ ]* 5.4 Write property test for activity list rendering
  - **Property 19: Activity list rendering**
  - **Validates: Requirements 4.1**
-

- [x] 6. Implement bottom navigation bar







  - Create bottom navigation bar with exactly 5 items
  - Configure navigation items: Home, Health, Track, Progress, Profile
  - Implement Solar Icons for navigation (with Material fallback)
  - Apply theme colors for selected/unselected states
  - Wire up selectedNavIndexProvider
  - Add navigation routing for all items
  - Apply styling (height, icon size, elevation)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ]* 6.1 Write property test for icon sizing consistency
  - **Property 9: Icon sizing consistency**
  - **Validates: Requirements 6.7**

- [x] 7. Assemble HomeScreen with all sections




  - Create HomeScreen root widget
  - Add Scaffold structure
  - Integrate HomeHeader as AppBar
  - Add RefreshIndicator for pull-to-refresh
  - Add SingleChildScrollView for scrolling
  - Integrate StatsSection
  - Integrate CTASection
  - Integrate RecentActivitySection
  - Add section spacing (24dp minimum)
  - Integrate bottom navigation bar
  - _Requirements: 8.1, 9.4, 10.1, 10.2, 10.3, 10.4_

- [ ]* 7.1 Write property test for section spacing consistency
  - **Property 17: Section spacing consistency**
  - **Validates: Requirements 9.4**

- [ ]* 7.2 Write property test for section header styling consistency
  - **Property 18: Section header styling consistency**
  - **Validates: Requirements 9.5, 9.6**

- [ ] 8. Implement pull-to-refresh functionality
  - Wire RefreshIndicator to provider refresh
  - Invalidate dailyStatsProvider on refresh
  - Invalidate recentActivitiesProvider on refresh
  - Handle loading indicator display
  - Handle successful refresh completion
  - Handle failed refresh with error message
  - _Requirements: 8.2, 8.3, 8.4, 8.5_

- [ ]* 8.1 Write property test for refresh triggers provider updates
  - **Property 15: Refresh triggers provider updates**
  - **Validates: Requirements 8.2**

- [ ]* 8.2 Write property test for refresh completion handling
  - **Property 16: Refresh completion handling**
  - **Validates: Requirements 8.4, 8.5**

- [ ] 9. Implement theme consistency across all components
  - Verify all colors use theme.colorScheme
  - Verify all text styles use theme.textTheme
  - Verify all cards use theme styling
  - Verify all buttons use theme styling
  - Test with both light and dark themes
  - _Requirements: 6.1, 6.2_

- [ ]* 9.1 Write property test for theme usage consistency
  - **Property 8: Theme usage consistency**
  - **Validates: Requirements 6.1, 6.2**

- [ ] 10. Implement provider reactivity
  - Verify widgets rebuild on provider data changes
  - Test provider state transitions (loading → data → error)
  - Verify automatic UI updates when providers change
  - _Requirements: 5.5_

- [ ]* 10.1 Write property test for provider reactivity
  - **Property 14: Provider reactivity**
  - **Validates: Requirements 5.5**

- [ ] 11. Add error handling and validation
  - Implement data validation for DailyStats
  - Implement data validation for RecentActivity
  - Add error boundaries for widget builds
  - Add fallback UI for errors
  - Add logging for debugging
  - _Requirements: All error handling from design_

- [ ] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Add accessibility features
  - Add semantic labels to all interactive elements
  - Add tooltips to icon-only buttons
  - Verify touch targets are minimum 48x48dp
  - Test with screen reader
  - Verify color contrast meets WCAG AA standards
  - _Requirements: Accessibility from design_

- [ ]* 13.1 Write unit tests for accessibility features
  - Test semantic labels are present
  - Test touch target sizes
  - Test screen reader announcements

- [ ] 14. Final integration and polish
  - Test all navigation flows
  - Test pull-to-refresh in all states
  - Test with empty data
  - Test with error states
  - Test with loading states
  - Verify performance (smooth scrolling, fast rebuilds)
  - Test on multiple screen sizes
  - _Requirements: All requirements_

- [ ]* 14.1 Write integration tests for complete user flows
  - Test complete dashboard load flow
  - Test navigation flows
  - Test refresh flows
  - Test error recovery flows

- [ ] 15. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
