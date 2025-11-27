# Supabase Database Setup Instructions

This guide will help you set up the database schema for the FlowFit authentication and onboarding system.

## Prerequisites

- A Supabase project (create one at https://app.supabase.com if you haven't already)
- Your Supabase project URL and anon key (already configured in `lib/secrets.dart`)

## Quick Setup (5 minutes)

### Step 1: Access Supabase SQL Editor

1. Go to https://app.supabase.com
2. Select your FlowFit project
3. Click on "SQL Editor" in the left sidebar

### Step 2: Run the Migration

1. Click "New query" button
2. Open the file `supabase/migrations/combined_migration.sql` from this repository
3. Copy the entire contents
4. Paste into the SQL Editor
5. Click "Run" (or press Ctrl+Enter / Cmd+Enter)

You should see a success message indicating the migration was applied.

### Step 3: Verify the Setup

Run this verification query in the SQL Editor:

```sql
-- Check if table exists with correct structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user_profiles';

-- Check policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- Check triggers
SELECT trigger_name 
FROM information_schema.triggers 
WHERE event_object_table = 'user_profiles';
```

Expected results:
- 12 columns in user_profiles table
- rowsecurity = true
- 3 policies (view, insert, update)
- 1 trigger (update_user_profiles_updated_at)

## Alternative: Individual Migration Files

If you prefer to run migrations separately, execute them in this order:

1. `001_create_user_profiles_table.sql`
2. `002_configure_rls_policies.sql`
3. `003_add_updated_at_trigger.sql`

## Testing the Setup

After applying the migrations, you can test the setup with these queries:

### Test 1: Insert a test profile (will fail due to RLS - expected)

```sql
-- This should fail because you're not authenticated as a user
INSERT INTO user_profiles (
  user_id,
  full_name,
  age,
  gender,
  weight,
  height,
  activity_level,
  goals,
  daily_calorie_target
) VALUES (
  gen_random_uuid(),
  'Test User',
  25,
  'male',
  70.5,
  175.0,
  'moderately_active',
  ARRAY['weight_loss', 'muscle_gain'],
  2000
);
```

This should fail with an RLS policy violation - this is correct behavior!

### Test 2: Check constraints

```sql
-- This should fail due to age constraint
INSERT INTO user_profiles (
  user_id,
  full_name,
  age,
  gender,
  weight,
  height,
  activity_level,
  goals,
  daily_calorie_target
) VALUES (
  gen_random_uuid(),
  'Test User',
  10,  -- Too young (< 13)
  'male',
  70.5,
  175.0,
  'moderately_active',
  ARRAY['weight_loss'],
  2000
);
```

This should fail with a CHECK constraint violation - this is correct!

## Troubleshooting

### Error: "relation 'user_profiles' already exists"

The table already exists. You can either:
- Skip the migration (table is already set up)
- Drop the existing table first (WARNING: this deletes all data):
  ```sql
  DROP TABLE IF EXISTS user_profiles CASCADE;
  ```
  Then run the migration again.

### Error: "policy already exists"

The policies are already configured. You can skip this step or drop existing policies:
```sql
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
```

### Error: "trigger already exists"

The trigger is already configured. You can skip this step or drop the existing trigger:
```sql
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
```

## Next Steps

After successfully setting up the database:

1. ✅ Database schema is ready
2. ✅ Row Level Security is configured
3. ✅ Automatic timestamp updates are enabled
4. 🚀 You can now run the FlowFit app and test the authentication flow

The app will automatically use this database schema when users:
- Sign up for an account
- Complete the onboarding survey
- Save their profile data

## Security Notes

- **Row Level Security (RLS)** ensures users can only access their own data
- **CHECK constraints** enforce data validation at the database level
- **Foreign key constraint** ensures profile data is automatically deleted when a user account is deleted
- **Anon key** is safe for client-side use because RLS policies protect the data

## Support

If you encounter any issues:
1. Check the Supabase logs in the dashboard
2. Verify your Supabase project URL and anon key in `lib/secrets.dart`
3. Ensure you're using the correct Supabase project
4. Review the error messages in the SQL Editor for specific constraint violations
