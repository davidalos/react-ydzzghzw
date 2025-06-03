/*
  # Role Change Security Fix

  1. Changes
    - Drop existing profile update policy
    - Add new policy for self-updates (excluding role changes)
    - Add new policy for manager-only role updates
    
  2. Security
    - Regular users can update their own profile except role
    - Only managers can update roles
*/

-- Drop existing update policy
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Allow users to update their own profile except role
CREATE POLICY "Allow self update except role"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND (
      -- Only allow updating fields other than role
      NEW.role = OLD.role
    )
  );

-- Allow managers to update any profile including role
CREATE POLICY "Managers can update profiles"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );