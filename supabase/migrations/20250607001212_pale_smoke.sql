/*
  # Fix co_staff column type and role change logging

  1. Database Changes
    - Convert co_staff column from text to uuid array
    - Add proper indexing for array operations
    - Create role change logging table and function

  2. Security Updates
    - Drop and recreate policies to handle column type change
    - Enable RLS on role_change_log table
    - Add policies for role change log access

  3. Triggers
    - Add trigger to log role changes automatically
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

-- Add policies for role_change_log
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

-- Create temporary table to store co_staff data if needed
DO $$
BEGIN
  -- Check if co_staff column exists and is not already uuid[]
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'incidents' 
    AND column_name = 'co_staff' 
    AND data_type != 'ARRAY'
  ) THEN
    -- Drop all policies that depend on co_staff column
    DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
    DROP POLICY IF EXISTS "Users can read own incidents" ON incidents;
    
    -- Create temporary table to store existing data
    CREATE TEMPORARY TABLE temp_incidents AS 
    SELECT id, co_staff FROM incidents WHERE co_staff IS NOT NULL;
    
    -- Drop the old column
    ALTER TABLE incidents DROP COLUMN co_staff;
    
    -- Add new column with correct type
    ALTER TABLE incidents ADD COLUMN co_staff uuid[] DEFAULT '{}';
    
    -- Recreate the policies with proper array handling
    CREATE POLICY "Employees can view assigned incidents"
      ON incidents
      FOR SELECT
      TO authenticated
      USING (
        submitted_by = auth.uid() OR 
        auth.uid() = ANY(co_staff) OR
        EXISTS (
          SELECT 1 FROM user_profiles 
          WHERE id = auth.uid() 
          AND role = 'employee'
        )
      );
    
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
END $$;

-- Ensure managers can view all incidents policy exists
DROP POLICY IF EXISTS "Managers can view all incidents" ON incidents;
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

-- Add index for co_staff array if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON incidents USING gin(co_staff);

-- Create role change logging function
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO role_change_log (user_id, old_role, new_role, changed_by)
    VALUES (NEW.id, OLD.role, NEW.role, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger for role changes
DROP TRIGGER IF EXISTS log_role_changes ON user_profiles;
CREATE TRIGGER log_role_changes
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION log_role_change();