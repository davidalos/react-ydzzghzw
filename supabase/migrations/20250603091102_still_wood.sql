/*
  # Update user profile policies

  1. Changes
    - Drop existing update policies
    - Create new policy for self-updates (excluding role changes)
    - Create new policy for manager updates (including role changes)
  
  2. Security
    - Regular users can only update their own profile (excluding role)
    - Managers can update any profile including roles
*/

-- Drop all existing update policies for user_profiles
DROP POLICY IF EXISTS "users_self_update_policy" ON user_profiles;
DROP POLICY IF EXISTS "managers_update_policy" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow self update except role" ON user_profiles;
DROP POLICY IF EXISTS "Managers can update profiles" ON user_profiles;

-- Allow users to update their own profile except role
CREATE POLICY "user_profile_self_update_v2"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow managers to update any profile including role
CREATE POLICY "manager_profile_update_v2"
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