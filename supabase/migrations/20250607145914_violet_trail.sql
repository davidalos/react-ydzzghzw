/*
  # Clean up duplicate table definitions

  This migration ensures we only have one definition of role_change_log
  and removes any duplicate CREATE statements from other migrations.
*/

-- Ensure role_change_log exists with the correct structure
CREATE TABLE IF NOT EXISTS role_change_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id),
  old_role text,
  new_role text,
  changed_by uuid REFERENCES user_profiles(id),
  changed_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE role_change_log ENABLE ROW LEVEL SECURITY;

-- Create policy for managers to view role changes
CREATE POLICY "Managers can view all role changes"
  ON role_change_log
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'manager'
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_role_change_log_user_id ON role_change_log(user_id);
CREATE INDEX IF NOT EXISTS idx_role_change_log_changed_at ON role_change_log(changed_at DESC);