/*
  # Fix Migration Dependencies and Policy Conflicts

  1. Database Structure
    - Create role_change_log table with proper RLS
    - Modify incidents.co_staff to UUID array type
    - Add performance indexes

  2. Security
    - Enable RLS on role_change_log table
    - Create policies for role-based access
    - Add role change logging trigger

  3. Performance
    - Add GIN index for co_staff array operations
    - Add indexes for common query patterns
*/

-- Step 1: Create role_change_log table if it doesn't exist
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

-- Step 2: Drop and recreate role_change_log policies to avoid conflicts
DROP POLICY IF EXISTS "Managers can view all role changes" ON role_change_log;
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

-- Step 3: Drop all existing policies that depend on co_staff column
DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
DROP POLICY IF EXISTS "Enhanced incident access" ON incidents;
DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;
DROP POLICY IF EXISTS "Managers can view all incidents" ON incidents;

-- Step 4: Handle co_staff column modification safely
DO $$
BEGIN
  -- Check if co_staff column exists and modify it
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'incidents' AND column_name = 'co_staff'
  ) THEN
    -- Check current data type
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'incidents' 
      AND column_name = 'co_staff' 
      AND data_type != 'ARRAY'
    ) THEN
      -- Create temporary table to store existing data if needed
      CREATE TEMPORARY TABLE IF NOT EXISTS temp_co_staff AS 
      SELECT id, co_staff FROM incidents WHERE co_staff IS NOT NULL;
      
      -- Drop the existing column
      ALTER TABLE incidents DROP COLUMN co_staff;
      
      -- Add new column as UUID array
      ALTER TABLE incidents ADD COLUMN co_staff uuid[] DEFAULT '{}';
    END IF;
  ELSE
    -- Column doesn't exist, create it
    ALTER TABLE incidents ADD COLUMN co_staff uuid[] DEFAULT '{}';
  END IF;
END $$;

-- Step 5: Add indexes for performance (drop first to avoid conflicts)
DROP INDEX IF EXISTS idx_incidents_co_staff;
CREATE INDEX idx_incidents_co_staff ON incidents USING gin(co_staff);

DROP INDEX IF EXISTS idx_incidents_submitted_by;
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_by ON incidents(submitted_by);

DROP INDEX IF EXISTS idx_incidents_created_at;
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incidents(created_at DESC);

DROP INDEX IF EXISTS idx_role_change_log_user_id;
CREATE INDEX IF NOT EXISTS idx_role_change_log_user_id ON role_change_log(user_id);

DROP INDEX IF EXISTS idx_role_change_log_changed_at;
CREATE INDEX IF NOT EXISTS idx_role_change_log_changed_at ON role_change_log(changed_at DESC);

-- Step 6: Recreate all incident policies with proper UUID array logic
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

-- Step 7: Create or replace role change logging function
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

-- Step 8: Add trigger for role changes (drop first to avoid conflicts)
DROP TRIGGER IF EXISTS log_role_changes ON user_profiles;
CREATE TRIGGER log_role_changes
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION log_role_change();

-- Step 9: Add missing constraints safely
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
  
  -- Ensure proper foreign key constraints exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'role_change_log_user_id_fkey'
  ) THEN
    ALTER TABLE role_change_log 
    ADD CONSTRAINT role_change_log_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES user_profiles(id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'role_change_log_changed_by_fkey'
  ) THEN
    ALTER TABLE role_change_log 
    ADD CONSTRAINT role_change_log_changed_by_fkey 
    FOREIGN KEY (changed_by) REFERENCES user_profiles(id);
  END IF;
END $$;

-- Step 10: Clean up any temporary tables
DROP TABLE IF EXISTS temp_co_staff;