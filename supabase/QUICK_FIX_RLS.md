# Quick Fix for RLS Policy Error

## Current Error

```
PostgrestException(message: new row violates row-level security policy for table "user_profiles", code: 42501, details: Unauthorized)
```

## What This Means

The table exists ✅ but the Row Level Security (RLS) policies are blocking your insert. The user is authenticated but the policy check is failing.

## Quick Fix (2 minutes)

### Open Supabase SQL Editor

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor**

### Run This Script

Copy and paste this entire script and click **RUN**:

```sql
-- Fix RLS Policy Issue
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Recreate with TO authenticated clause
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

**Expected Result**: ✅ Success. No rows returned.

### Test Your App

1. Close app completely
2. Reopen app
3. Sign up with new account
4. Complete survey
5. Should work now! ✅

## What Changed

The original policies were missing the `TO authenticated` clause, which explicitly specifies that only authenticated users can perform these operations. This is more explicit and reliable than relying on implicit authentication checks.

## Verify It Worked

Run this to check policies:

```sql
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'user_profiles';
```

Should show:
- Users can view own profile | SELECT | {authenticated}
- Users can insert own profile | INSERT | {authenticated}
- Users can update own profile | UPDATE | {authenticated}

## Still Having Issues?

If you still get the error after running the fix:

1. **Check user is authenticated**: The error might mean the user isn't properly logged in
2. **Check user_id matches**: Verify the user_id being inserted matches auth.uid()
3. **Reload schema cache**: Settings → API → Reload schema cache
4. **Check Supabase logs**: Logs → Postgres Logs to see detailed error

## Root Cause

The RLS policies need to explicitly specify `TO authenticated` to ensure only authenticated users can access the table. Without this, Supabase might not properly enforce the authentication requirement.
