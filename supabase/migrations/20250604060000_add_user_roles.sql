/*
  # Add user_roles table

  1. Changes
    - create table mapping users to roles
    - seed from existing user_profiles
    - trigger to keep roles in sync
    - enable RLS with policy for users to read their role

  2. Security
    - ensures policies referencing user_roles function correctly
*/

-- Create table if missing
CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('employee', 'manager')),
  created_at timestamptz DEFAULT now()
);

-- Populate with current roles
INSERT INTO user_roles (id, role)
SELECT id, role FROM user_profiles
ON CONFLICT (id) DO NOTHING;

-- Function to sync changes from user_profiles
CREATE OR REPLACE FUNCTION sync_user_roles()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_roles(id, role)
  VALUES (NEW.id, NEW.role)
  ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for inserts and updates on user_profiles
DROP TRIGGER IF EXISTS trg_sync_user_roles ON user_profiles;
CREATE TRIGGER trg_sync_user_roles
AFTER INSERT OR UPDATE OF role ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION sync_user_roles();

-- Row level security
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "User can read own role" ON user_roles;
CREATE POLICY "User can read own role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);
