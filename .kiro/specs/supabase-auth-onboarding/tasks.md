# Implementation Plan: Supabase Authentication and Onboarding

- [x] 1. Set up Supabase configuration and initialization





  - Create `lib/secrets.dart` with Supabase URL and anon key
  - Initialize Supabase in `main.dart` before app starts
  - Add secrets.dart to .gitignore
  - Verify Supabase connection works
  - _Requirements: 1.1, 2.1_

- [x] 2. Create domain layer entities and interfaces





  - [x] 2.1 Implement domain entities


    - Create `lib/domain/entities/user.dart` with User entity
    - Create `lib/domain/entities/user_profile.dart` with UserProfile entity
    - Create `lib/domain/entities/auth_state.dart` with AuthState and AuthStatus
    - _Requirements: 1.1, 2.1, 3.1_

  - [x] 2.2 Define repository interfaces


    - Create `lib/domain/repositories/i_auth_repository.dart` interface
    - Create `lib/domain/repositories/i_profile_repository.dart` interface
    - Define all method signatures for auth and profile operations
    - _Requirements: 1.1, 2.1, 4.1_

  - [x] 2.3 Create domain exception types


    - Create `lib/domain/exceptions/auth_exceptions.dart`
    - Implement InvalidEmailException, WeakPasswordException, EmailAlreadyExistsException
    - Implement InvalidCredentialsException, NetworkException, UnknownException
    - _Requirements: 7.1, 7.2, 7.5_

- [x] 3. Implement data layer models and repositories





  - [x] 3.1 Create data models


    - Create `lib/data/models/user_model.dart` with JSON serialization
    - Create `lib/data/models/user_profile_model.dart` with JSON serialization
    - Implement `toDomain()` and `fromDomain()` conversion methods
    - _Requirements: 1.1, 4.1_



  - [x] 3.2 Implement AuthRepository





    - Create `lib/data/repositories/auth_repository.dart`
    - Implement signUp method with email validation and Supabase integration
    - Implement signIn method with credential validation
    - Implement signOut method with session cleanup
    - Implement getCurrentUser and authStateChanges methods
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.5_

  - [ ]* 3.3 Write property test for email validation
    - **Property 2: Invalid email formats are rejected locally**
    - **Validates: Requirements 1.3**

  - [ ]* 3.4 Write property test for authentication
    - **Property 1: Valid credentials create accounts**


    - **Property 3: Valid credentials authenticate users**
    - **Validates: Requirements 1.1, 2.1**

  - [x] 3.5 Implement ProfileRepository





    - Create `lib/data/repositories/profile_repository.dart`
    - Implement createProfile method with retry logic (max 3 attempts)
    - Implement updateProfile method
    - Implement getProfile and hasCompletedSurvey methods
    - _Requirements: 4.1, 4.2, 4.3, 5.3, 5.4_

  - [ ]* 3.6 Write property test for profile persistence
    - **Property 9: Complete survey data saves to Supabase**
    - **Validates: Requirements 4.1**

- [x] 4. Create presentation layer state management





  - [x] 4.1 Implement AuthNotifier


    - Create `lib/presentation/notifiers/auth_notifier.dart`
    - Implement StateNotifier with AuthState
    - Implement signUp, signIn, signOut methods
    - Implement session initialization and restoration logic
    - Add error handling and state updates
    - _Requirements: 1.1, 2.1, 2.3, 2.5, 5.1, 5.2_

  - [ ]* 4.2 Write property test for session persistence
    - **Property 4: Successful login persists session**
    - **Property 10: Valid session restores auth state**
    - **Validates: Requirements 2.3, 5.2**

  - [ ]* 4.3 Write property test for logout
    - **Property 5: Logout clears all auth data**
    - **Validates: Requirements 2.5**

  - [x] 4.4 Implement SurveyNotifier


    - Create `lib/presentation/notifiers/survey_notifier.dart`
    - Implement StateNotifier with SurveyState
    - Implement updateSurveyData method with local persistence
    - Implement validation methods for each survey step
    - Implement submitSurvey method with error handling
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 4.1, 4.3_

  - [ ]* 4.5 Write property test for survey data persistence
    - **Property 6: Partial survey data persists across navigation**
    - **Validates: Requirements 3.2**

  - [ ]* 4.6 Write property test for survey validation
    - **Property 7: Required survey fields are validated**
    - **Property 8: Numeric survey inputs are range-validated**
    - **Validates: Requirements 3.3, 3.4**

  - [x] 4.7 Set up Riverpod providers


    - Create `lib/presentation/providers/providers.dart`
    - Define authRepositoryProvider and profileRepositoryProvider
    - Define authNotifierProvider and surveyNotifierProvider
    - _Requirements: 8.1, 8.4_

- [x] 5. Update authentication screens with Supabase integration





  - [x] 5.1 Update SignUpScreen


    - Connect form to authNotifierProvider
    - Implement real signUp call instead of mock
    - Add loading states and error handling
    - Navigate to survey intro on success
    - Keep consent checkboxes and validation
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.1_

  - [x] 5.2 Update LoginScreen


    - Connect form to authNotifierProvider
    - Implement real signIn call instead of mock
    - Add loading states and error handling
    - Keep Google/Apple buttons as dashboard shortcuts (no auth)
    - Navigate based on profile completion status
    - _Requirements: 2.1, 2.2, 5.3, 5.4, 6.1, 6.2, 6.3_

  - [ ]* 5.3 Write unit test for duplicate email handling
    - Test that attempting to register with existing email shows appropriate error
    - **Validates: Requirements 1.2**

  - [ ]* 5.4 Write unit test for invalid credentials
    - Test that login with wrong password shows appropriate error
    - **Validates: Requirements 2.2**

- [x] 6. Implement survey screens with data persistence







  - [x] 6.1 Create SurveyBasicInfoScreen



    - Create `lib/screens/onboarding/survey_basic_info_screen.dart`
    - Add form fields for name, age, gender
    - Connect to surveyNotifierProvider
    - Implement validation for required fields
    - Save data on next button press
    - _Requirements: 3.2, 3.3_

  - [x] 6.2 Create SurveyBodyMeasurementsScreen








    - Create `lib/screens/onboarding/survey_body_measurements_screen.dart`
    - Add form fields for weight and height
    - Implement numeric validation with range checks
    - Connect to surveyNotifierProvider
    - Save data on next button press
    - _Requirements: 3.2, 3.4_



  - [x] 6.3 Create SurveyActivityGoalsScreen

    - Create `lib/screens/onboarding/survey_activity_goals_screen.dart`
    - Add activity level selector
    - Add goals multi-select (at least one required)
    - Connect to surveyNotifierProvider
    - Save data on next button press
    - _Requirements: 3.2, 3.5_

  - [x] 6.4 Create SurveyDailyTargetsScreen
    - Create `lib/screens/onboarding/survey_daily_targets_screen.dart`
    - Calculate and display daily calorie target
    - Show summary of all survey data
    - Implement submit button that calls surveyNotifier.submitSurvey()
    - Navigate to dashboard on success
    - _Requirements: 4.1, 4.5_

  - [x] 6.5 Update SurveyIntroScreen
    - Connect to authNotifierProvider to get user name
    - Update navigation to pass user ID to survey flow
    - _Requirements: 3.1_

  - [ ]* 6.6 Write unit test for survey validation edge cases
    - Test age boundary values (12, 13, 120, 121)
    - Test weight/height boundary values
    - Test empty goals array
    - **Validates: Requirements 3.3, 3.4, 3.5**

- [x] 7. Implement app initialization and routing logic



  - [x] 7.1 Update main.dart with auth-based routing


    - Wrap app with ProviderScope
    - Check auth state on app start
    - Route to dashboard if authenticated with complete profile
    - Route to survey if authenticated without complete profile
    - Route to welcome screen if not authenticated
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 7.2 Create splash screen for loading state


    - Create `lib/screens/splash_screen.dart`
    - Show loading indicator while checking auth state
    - _Requirements: 5.1_

- [x] 8. Set up Supabase database schema




  - [x] 8.1 Create user_profiles table


    - Execute SQL to create user_profiles table with all columns
    - Add CHECK constraints for age, weight, height, gender, activity_level
    - Add index on user_id
    - _Requirements: 4.1_

  - [x] 8.2 Configure Row Level Security


    - Enable RLS on user_profiles table
    - Create policy for users to view own profile
    - Create policy for users to insert own profile
    - Create policy for users to update own profile
    - _Requirements: 4.1_

  - [x] 8.3 Add updated_at trigger


    - Create update_updated_at_column function
    - Create trigger on user_profiles table
    - _Requirements: 4.1_

- [ ] 9. Implement error handling and logging









  - [x] 9.1 Create error logger utility



    - Create `lib/core/utils/error_logger.dart`
    - Implement logError method that logs to console in debug
    - Ensure no sensitive data is logged
    - _Requirements: 7.2_

  - [ ]* 9.2 Write property test for error message sanitization
    - **Property 11: Error messages don't expose technical details**
    - **Validates: Requirements 7.5**

  - [x] 9.3 Add error handling to all repository methods



    - Wrap Supabase calls in try-catch blocks
    - Map Supabase errors to domain exceptions
    - Log errors using error logger
    - _Requirements: 7.1, 7.2, 7.3, 7.5_

  - [x] 9.4 Write unit test for retry logic



    - Test that profile save retries up to 3 times on failure
    - **Validates: Requirements 4.3**

  - [ ] 9.5 Write unit test for error logging

    - Test that Supabase errors are logged with context
    - **Validates: Requirements 7.2**
-


- [x] 10. Checkpoint - Ensure all tests pass









  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Final integration and testing





  - [x] 11.1 Test complete signup flow


    - Manually test signup → survey → dashboard flow
    - Verify data persists in Supabase
    - Test error cases (duplicate email, network errors)
    - _Requirements: 1.1, 3.1, 4.1, 4.5_

  - [x] 11.2 Test complete login flow

    - Manually test login → dashboard flow
    - Test login → survey flow for incomplete profiles
    - Test session persistence across app restarts
    - _Requirements: 2.1, 5.2, 5.3, 5.4_

  - [x] 11.3 Test social sign-in shortcuts

    - Verify Google/Apple buttons navigate to dashboard
    - Verify no auth session is created
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ]* 11.4 Write integration test for complete auth flow
    - Test signup → survey → save → dashboard flow end-to-end
    - Test login → dashboard flow for existing users
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1_

- [ ] 12. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
