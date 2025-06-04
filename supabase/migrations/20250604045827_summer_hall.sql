/*
  # Fix UUID Comparison and Role Management

  1. Changes
    - Fix UUID comparison in policies
    - Add proper type casting for UUID arrays
    - Improve role management policies
    
  2. Security
    - Ensure proper type handling
    - Maintain existing security model
*/

-- Fix UUID comparison in co_staff array
ALTER TABLE incidents 
  ALTER COLUMN co_staff TYPE uuid[] USING array_remove(ARRAY(
    SELECT CAST(NULLIF(TRIM(s), '') AS uuid) 
    FROM unnest(co_staff) s 
    WHERE NULLIF(TRIM(s), '') IS NOT NULL
  ), NULL);

-- Update the employees policy to handle UUID comparison correctly
DROP POLICY IF EXISTS "Employees can view assigned incidents" ON incidents;
CREATE POLICY "Employees can view assigned incidents"
  ON incidents
  FOR SELECT
  TO authenticated
  USING (
    submitted_by = auth.uid() OR 
    auth.uid()::uuid = ANY(co_staff) OR
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
    VALUES (
      NEW.id::uuid, 
      OLD.role, 
      NEW.role, 
      auth.uid()::uuid
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;