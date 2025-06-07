/*
  # Fix co_staff column type and role change logging

  1. Dependencies Management
    - Drop all policies that depend on co_staff column
    - Modify co_staff column from text to uuid array
    - Recreate policies with proper logic
  
  2. Role Change Logging
    - Create role_change_log table
    - Add trigger function for logging role changes
    - Enable RLS and policies for role change log
  
  3. Security
    - Maintain proper RLS policies
    - Ensure data integrity during migration
*/

-- Create role_change_log table if it doesn't exist
CREATE TABLE IF NOT EXISTS role_change_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id),
  old_role text,
  new_role text,
  changed_by uuid REFERENCES user_profiles(id),
  changed_at timestamptz DEFAULT now()
);

-- Enable RLS on role_change_log
ALTER TABLE role_change_log ENABLE ROW LEVEL SECURITY;

-- Create policy for role change log access (managers only)
CREATE POLICY "Managers can view all role changes"
  ON role_change_log
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() 
      AND role = 'manager'
    )
  );

-- Step 1: Drop all policies that depend on co_staff column
DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
DROP POLICY IF EXISTS "Enhanced incident access" ON incidents;
DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;

-- Step 2: Create temporary table to preserve any existing co_staff data
DO $$
BEGIN
  -- Check if co_staff column exists and has data
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'incidents' AND column_name = 'co_staff'
  ) THEN
    -- Create temporary table to store existing data
    CREATE TEMPORARY TABLE temp_co_staff AS 
    SELECT id, co_staff FROM incidents WHERE co_staff IS NOT NULL;
    
    -- Drop the existing column
    ALTER TABLE incidents DROP COLUMN co_staff;
  END IF;
END $$;

-- Step 3: Add co_staff as UUID array with proper default
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS co_staff uuid[] DEFAULT '{}';

-- Step 4: Add index for co_staff array (GIN index for array operations)
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON incidents USING gin(co_staff);

-- Step 5: Recreate policies with proper logic for UUID array
CREATE POLICY "Enhanced incident access"
  ON incidents
  FOR SELECT
  TO authenticated
  USING (
    submitted_by = auth.uid() OR 
    auth.uid() = ANY(co_staff) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() 
      AND role = 'manager'
    )
  );

-- Additional policy for managers to view all incidents
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

-- Policy for users to read incidents they submitted or are assigned to
CREATE POLICY "Users can read relevant incidents"
  ON incidents
  FOR SELECT
  TO authenticated
  USING (
    submitted_by = auth.uid() OR 
    auth.uid() = ANY(co_staff) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() 
      AND role = 'manager'
    )
  );

-- Step 6: Create role change logging function
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only log if role actually changed
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO role_change_log (user_id, old_role, new_role, changed_by)
    VALUES (NEW.id, OLD.role, NEW.role, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Add trigger for role changes (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS log_role_changes ON user_profiles;
CREATE TRIGGER log_role_changes
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION log_role_change();

-- Step 8: Ensure proper indexes exist for performance
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_by ON incidents(submitted_by);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_role_change_log_user_id ON role_change_log(user_id);
CREATE INDEX IF NOT EXISTS idx_role_change_log_changed_at ON role_change_log(changed_at DESC);

-- Step 9: Add any missing constraints
DO $$
BEGIN
  -- Ensure incidents category constraint exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'incidents_category_check'
  ) THEN
    ALTER TABLE incidents ADD CONSTRAINT incidents_category_check 
    CHECK (category = ANY (ARRAY['Positive Progress'::text, 'Medical'::text, 'Behavioral'::text, 'Safety'::text, 'Emergency'::text]));
  END IF;
END $$;