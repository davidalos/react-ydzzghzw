/*
  # Role Management and Access Control Updates

  1. Changes
    - Create role change logging table and trigger
    - Drop existing policies before modifying co_staff column
    - Convert co_staff to UUID array
    - Add new role-based access policies
    
  2. Security
    - Maintain RLS during changes
    - Proper UUID type handling
    - Role-based access control
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

-- Drop existing policies that depend on co_staff
DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
DROP POLICY IF EXISTS "Users can read own incidents" ON incidents;
DROP POLICY IF EXISTS "Managers can view all incidents" ON incidents;

-- Create temporary table to store co_staff data
CREATE TEMPORARY TABLE temp_incidents AS
SELECT id, co_staff FROM incidents;

-- Modify co_staff to be UUID array
ALTER TABLE incidents DROP COLUMN co_staff;
ALTER TABLE incidents ADD COLUMN co_staff uuid[] DEFAULT '{}';

-- Reinsert previous co_staff values
UPDATE incidents i
SET co_staff = t.co_staff::uuid[]
FROM temp_incidents t
WHERE i.id = t.id;

DROP TABLE temp_incidents;

-- Add index for co_staff array
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON incidents USING gin(co_staff);

-- Create new policies for proper role-based access
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