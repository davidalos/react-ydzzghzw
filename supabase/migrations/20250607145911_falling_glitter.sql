/*
  # Create user_roles table

  1. New Tables
    - `user_roles`
      - `id` (uuid, primary key, references auth.users)
      - `role` (text, default 'staff')
  
  2. Security
    - Enable RLS on `user_roles` table
    - Add policy for users to read their own role
*/

CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'staff',
  CONSTRAINT user_roles_role_check CHECK (role IN ('manager', 'staff'))
);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User can read own role"
  ON user_roles
  FOR SELECT
  TO public
  USING (auth.uid() = id);