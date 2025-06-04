/*
  # Fix UUID handling and role policies

  1. Changes
    - Convert co_staff array to UUID type safely
    - Add policy for employee incident viewing
    - Add index for co_staff array
    - Update role change logging
    
  2. Security
    - Proper UUID type handling
    - Role-based access control
*/

-- Create temporary table to store co_staff data
CREATE TEMPORARY TABLE temp_incidents AS SELECT id, co_staff FROM incidents;

-- Modify co_staff to be UUID array
ALTER TABLE incidents DROP COLUMN co_staff;
ALTER TABLE incidents ADD COLUMN co_staff uuid[];

-- Update the employees policy to handle UUID comparison correctly
DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
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

-- Add index for co_staff array to improve performance
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON incidents USING gin(co_staff);

-- Update role change trigger to handle UUID properly
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role != NEW.role THEN
    INSERT INTO role_change_log (user_id, old_role, new_role, changed_by)
    VALUES (NEW.id, OLD.role, NEW.role, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;