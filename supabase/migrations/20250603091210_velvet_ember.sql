/*
  # Role-based security implementation
  
  1. Changes
    - Drops all existing user_profiles update policies
    - Creates two new policies:
      a. Regular users can update their own profile except role
      b. Managers can update any profile including roles
  
  2. Security
    - Regular users cannot modify roles (their own or others)
    - Managers can update any profile and change roles
    - All updates are properly secured with RLS
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
CREATE POLICY "user_profile_self_update_v3"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    (OLD.role IS NOT DISTINCT FROM NEW.role)
  );

-- Create policy for managers (can update any profile including role)
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