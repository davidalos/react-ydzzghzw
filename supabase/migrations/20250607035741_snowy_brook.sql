/*
  # Remove co_staff column from incidents table

  1. Security Changes
    - Drop policies that reference co_staff column
    - Remove co_staff column from incidents table
    - Recreate simplified policies without co_staff references

  2. Changes Made
    - Removed "Enhanced incident access" policy
    - Removed "Users can read relevant incidents" policy  
    - Dropped co_staff column from incidents table
    - Recreated basic incident access policies
    - Maintained manager access to all incidents
    - Maintained user access to own incidents
*/

-- Step 1: Drop policies that depend on co_staff column
DROP POLICY IF EXISTS "Enhanced incident access" ON incidents;
DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;

-- Step 2: Drop the co_staff column
ALTER TABLE incidents DROP COLUMN IF EXISTS co_staff;

-- Step 3: Drop the co_staff index if it exists
DROP INDEX IF EXISTS idx_incidents_co_staff;

-- Step 4: Recreate basic incident policies without co_staff references
CREATE POLICY "Users can read own incidents"
  ON incidents
  FOR SELECT
  TO authenticated
  USING (
    submitted_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() 
      AND role = 'manager'
    )
  );

CREATE POLICY "Users can create incidents"
  ON incidents
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = submitted_by);

-- Step 5: Ensure managers can still view all incidents (policy should already exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incidents' 
    AND policyname = 'Managers can view all incidents'
  ) THEN
    CREATE POLICY "Managers can view all incidents"
      ON incidents
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM user_profiles 
          WHERE id = auth.uid() 
          AND role = 'manager'
        )
      );
  END IF;
END $$;