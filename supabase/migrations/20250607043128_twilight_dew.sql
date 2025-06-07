/*
  # Remove co_staff column and fix incident policies

  1. Changes Made
    - Remove co_staff column from incidents table
    - Drop related indexes and policies
    - Recreate simplified policies without co_staff references
    
  2. Security
    - Maintain RLS protection for incidents
    - Ensure users can only see their own incidents or managers see all
    - Preserve existing access patterns
*/

-- Step 1: Drop all existing incident policies to avoid conflicts
DROP POLICY IF EXISTS "Enhanced incident access" ON incidents;
DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;
DROP POLICY IF EXISTS "Users can read own incidents" ON incidents;
DROP POLICY IF EXISTS "Users can create incidents" ON incidents;
DROP POLICY IF EXISTS "Managers can view all incidents" ON incidents;

-- Step 2: Drop the co_staff column and related indexes
ALTER TABLE incidents DROP COLUMN IF EXISTS co_staff;
DROP INDEX IF EXISTS idx_incidents_co_staff;

-- Step 3: Recreate incident policies without co_staff references
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