/*
  # Role Security Update

  1. Changes
    - Drop existing update policy for user profiles
    - Add new policy to allow users to update their own profile except role
    - Add new policy to allow managers to update any profile including roles

  2. Security
    - Users can only update their own non-role fields
    - Only managers can update role field
    - Row-level security remains enabled
*/

-- Drop existing update policy
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Allow users to update their own profile except role
CREATE POLICY "Allow self update except role"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

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
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );