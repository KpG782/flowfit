# Supabase Database Migrations

This directory contains SQL migration files for setting up the FlowFit database schema in Supabase.

## Migration Files

1. **001_create_user_profiles_table.sql** - Creates the user_profiles table with all required columns, constraints, and indexes
2. **002_configure_rls_policies.sql** - Configures Row Level Security policies for the user_profiles table
3. **003_add_updated_at_trigger.sql** - Adds automatic timestamp update trigger for the updated_at column

## How to Apply Migrations

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard at https://app.supabase.com
2. Navigate to the SQL Editor (left sidebar)
3. Copy and paste the contents of each migration file in order (001, 002, 003)
4. Click "Run" to execute each migration
5. Verify the table was created by checking the Table Editor

### Option 2: Using Combined Migration File

For convenience, you can use the `combined_migration.sql` file which contains all migrations in the correct order:

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the entire contents of `combined_migration.sql`
4. Click "Run" to execute all migrations at once

### Option 3: Using Supabase CLI (Advanced)

If you have the Supabase CLI installed:

```bash
# Link your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push
```

## Database Schema

### user_profiles Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | UUID | PRIMARY KEY, REFERENCES auth.users(id) | Foreign key to auth.users |
| full_name | TEXT | NOT NULL | User's full name |
| age | INTEGER | NOT NULL, CHECK (13-120) | User's age in years |
| gender | TEXT | NOT NULL, CHECK (enum) | User's gender |
| weight | DECIMAL(5,2) | NOT NULL, CHECK (0-500) | User's weight in kg |
| height | DECIMAL(5,2) | NOT NULL, CHECK (0-300) | User's height in cm |
| activity_level | TEXT | NOT NULL, CHECK (enum) | User's activity level |
| goals | TEXT[] | NOT NULL | Array of user's fitness goals |
| daily_calorie_target | INTEGER | NOT NULL, CHECK (> 0) | Calculated daily calorie target |
| survey_completed | BOOLEAN | NOT NULL, DEFAULT false | Survey completion flag |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record update timestamp |

### Constraints

- **Age**: Must be between 13 and 120 years
- **Gender**: Must be one of: 'male', 'female', 'other', 'prefer_not_to_say'
- **Weight**: Must be greater than 0 and less than 500 kg
- **Height**: Must be greater than 0 and less than 300 cm
- **Activity Level**: Must be one of: 'sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'
- **Daily Calorie Target**: Must be greater than 0

### Row Level Security (RLS)

RLS is enabled on the user_profiles table with the following policies:

- **Users can view own profile**: Users can only SELECT their own profile data
- **Users can insert own profile**: Users can only INSERT their own profile record
- **Users can update own profile**: Users can only UPDATE their own profile data

### Triggers

- **update_user_profiles_updated_at**: Automatically updates the `updated_at` column to the current timestamp whenever a row is updated

## Verification

After applying the migrations, verify the setup:

```sql
-- Check if table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'user_profiles';

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user_profiles';

-- Check policies
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- Check triggers
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'user_profiles';
```

## Rollback

If you need to rollback the migrations:

```sql
-- Drop trigger
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Drop table (this will cascade delete all data)
DROP TABLE IF EXISTS user_profiles CASCADE;
```

## Notes

- The user_id column references auth.users(id) with ON DELETE CASCADE, meaning if a user is deleted from auth.users, their profile will be automatically deleted
- The updated_at trigger ensures the timestamp is always current when a profile is modified
- RLS policies ensure users can only access their own data, providing security at the database level
- All constraints are enforced at the database level for data integrity
