# Supabase Database Setup Guide

## Error You're Seeing

```
PostgrestException(message: Could not find the table 'public.user_profiles' in the schema cache, code: PGRST205)
```

This means the `user_profiles` table doesn't exist in your Supabase database yet.

## Quick Fix (5 minutes)

### Step 1: Open Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your project: `dnasghxxqwibwqnljvxr`
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run Migration Scripts

Copy and paste each SQL script below into the SQL Editor and click **RUN**.

#### Script 1: Create user_profiles Table

```sql
-- Create user_profiles table with all required columns and constraints
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13 AND age <= 120),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 500),
  height DECIMAL(5,2) NOT NULL CHECK (height > 0 AND height < 300),
  activity_level TEXT NOT NULL CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
  goals TEXT[] NOT NULL,
  daily_calorie_target INTEGER NOT NULL CHECK (daily_calorie_target > 0),
  survey_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Add comment to table
COMMENT ON TABLE user_profiles IS 'Stores user profile data collected during onboarding survey';
```

**Expected Result**: ✅ Success. No rows returned.

---

#### Script 2: Configure Row Level Security (RLS)

```sql
-- Enable Row Level Security on user_profiles table
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id);
```

**Expected Result**: ✅ Success. No rows returned.

---

#### Script 3: Add Updated At Trigger

```sql
-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Create trigger on user_profiles table
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

**Expected Result**: ✅ Success. No rows returned.

---

### Step 3: Verify Table Creation

Run this query to verify the table exists:

```sql
SELECT * FROM user_profiles LIMIT 1;
```

**Expected Result**: ✅ Success. 0 rows returned (table is empty but exists).

---

### Step 4: Test Your App

1. Close your app completely
2. Reopen the app
3. Try signing up with a new account
4. Complete the survey
5. The error should be gone! ✅

---

## Verify Setup

After running the scripts, verify everything is set up correctly:

### Check Table Structure

```sql
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;
```

**Expected Output**: Should show 12 columns (user_id, full_name, age, gender, weight, height, activity_level, goals, daily_calorie_target, survey_completed, created_at, updated_at)

### Check RLS Policies

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'user_profiles';
```

**Expected Output**: Should show 3 policies (view, insert, update)

### Check Trigger

```sql
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'user_profiles';
```

**Expected Output**: Should show 1 trigger (update_user_profiles_updated_at)

---

## Alternative: Run Combined Migration

If you prefer, you can run all three scripts at once:

```sql
-- ============================================
-- COMBINED MIGRATION SCRIPT
-- ============================================

-- 1. Create user_profiles table
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13 AND age <= 120),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 500),
  height DECIMAL(5,2) NOT NULL CHECK (height > 0 AND height < 300),
  activity_level TEXT NOT NULL CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
  goals TEXT[] NOT NULL,
  daily_calorie_target INTEGER NOT NULL CHECK (daily_calorie_target > 0),
  survey_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- 2. Enable RLS and create policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- 3. Create trigger function and trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## Troubleshooting

### Error: "relation 'user_profiles' already exists"

The table already exists. Skip to Step 3 to verify.

### Error: "permission denied for schema public"

You need to be the project owner or have proper permissions. Contact your Supabase project admin.

### Error: "policy already exists"

The policies are already created. This is fine, continue to the next step.

### Table exists but still getting PGRST205 error

1. Go to **Settings** → **API** in Supabase dashboard
2. Click **Reload schema cache** button
3. Wait 10 seconds
4. Try your app again

---

## What These Scripts Do

### Script 1: Create Table
- Creates `user_profiles` table with proper columns
- Adds constraints for data validation (age 13-120, weight 0-500, etc.)
- Creates index for fast lookups
- Links to `auth.users` table with foreign key

### Script 2: Row Level Security
- Enables RLS to protect user data
- Creates policies so users can only access their own data
- Prevents users from seeing other users' profiles

### Script 3: Auto-Update Timestamp
- Creates trigger to automatically update `updated_at` field
- Runs every time a profile is updated
- Keeps track of when data was last modified

---

## Next Steps

After setting up the database:

1. ✅ Test signup flow
2. ✅ Test survey completion
3. ✅ Verify data saves to Supabase
4. ✅ Test login flow
5. ✅ Test session persistence

Refer to `test/integration/MANUAL_TESTING_GUIDE.md` for detailed testing instructions.

---

## Need Help?

- **Supabase Docs**: https://supabase.com/docs/guides/database
- **SQL Editor**: https://supabase.com/dashboard/project/_/sql
- **Table Editor**: https://supabase.com/dashboard/project/_/editor

---

## Summary

**Problem**: `user_profiles` table doesn't exist  
**Solution**: Run the SQL scripts above in Supabase SQL Editor  
**Time**: 5 minutes  
**Result**: App will work correctly ✅
