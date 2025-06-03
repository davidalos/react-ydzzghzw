/*
  # Fix role security policies

  1. Changes
    - Drop all existing update policies for user_profiles
    - Create new policy for regular users that prevents role changes
    - Create new policy for managers to update any profile
  
  2. Security
    - Regular users can only update their own profile, excluding role field
    - Managers can update any profile including roles
*/

-- Drop all existing update policies for user_profiles
DROP POLICY IF EXISTS "user_profile_self_update_v2" ON user_profiles;
DROP POLICY IF EXISTS "manager_profile_update_v2" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow self update except role" ON user_profiles;
DROP POLICY IF EXISTS "Managers can update profiles" ON user_profiles;
DROP POLICY IF EXISTS "users_self_update_policy" ON user_profiles;
DROP POLICY IF EXISTS "managers_update_policy" ON user_profiles;

-- Create policy for regular users (can update own profile except role)
DO $$ 
BEGIN
  CREATE POLICY "user_profile_self_update_v3"
    ON user_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (
      auth.uid() = id AND
      role = (SELECT role FROM user_profiles WHERE id = auth.uid())
    );
END $$;

-- Create policy for managers (can update any profile including role)
DO $$
BEGIN
  CREATE POLICY "manager_profile_update_v3"
    ON user_profiles
    FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'manager'
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'manager'
      )
    );
END $$;