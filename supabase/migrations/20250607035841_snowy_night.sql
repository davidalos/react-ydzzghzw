/*
  # Remove co_staff column and update incident policies

  1. Changes Made
    - Remove co_staff column from incidents table
    - Drop related index
    - Update RLS policies to remove co_staff references
    
  2. Security
    - Maintain proper RLS policies for incident access
    - Ensure users can only read their own incidents or managers can read all
    - Preserve incident creation permissions
*/

-- Step 1: Drop policies that depend on co_staff column
DROP POLICY IF EXISTS "Enhanced incident access" ON incidents;
DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;
DROP POLICY IF EXISTS "Users can read own incidents" ON incidents;

-- Step 2: Drop the co_staff column
ALTER TABLE incidents DROP COLUMN IF EXISTS co_staff;

-- Step 3: Drop the co_staff index if it exists
DROP INDEX IF EXISTS idx_incidents_co_staff;

-- Step 4: Recreate basic incident policies without co_staff references
DO $$
BEGIN
  -- Create "Users can read own incidents" policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incidents' 
    AND policyname = 'Users can read own incidents'
  ) THEN
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
  END IF;

  -- Create "Users can create incidents" policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incidents' 
    AND policyname = 'Users can create incidents'
  ) THEN
    CREATE POLICY "Users can create incidents"
      ON incidents
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = submitted_by);
  END IF;

  -- Create "Managers can view all incidents" policy if it doesn't exist
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