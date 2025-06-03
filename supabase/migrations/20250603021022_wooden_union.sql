/*
  # Initial Database Setup

  1. Tables Created:
    - user_profiles: Store user information and roles
    - clients: Store client information
    - incidents: Track incidents with clients
    - goals: Track client goals
    - goal_updates: Track progress on goals

  2. Security:
    - Enable RLS on all tables
    - Set up appropriate access policies
    
  3. Test Data:
    - Insert sample clients
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS goal_updates CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('employee', 'manager')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Create clients table
CREATE TABLE clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can read clients"
  ON clients
  FOR SELECT
  TO authenticated
  USING (true);

-- Create incidents table
CREATE TABLE incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) NOT NULL,
  submitted_by uuid REFERENCES user_profiles(id) NOT NULL,
  category text NOT NULL,
  description text NOT NULL,
  reflection text,
  serious boolean DEFAULT false,
  co_staff text[],
  created_at timestamptz DEFAULT now()
);

ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employees can read own incidents"
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

-- Create goals table
CREATE TABLE goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) NOT NULL,
  created_by uuid REFERENCES user_profiles(id) NOT NULL,
  title text NOT NULL,
  description text,
  status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can read goals"
  ON goals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create goals"
  ON goals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own goals"
  ON goals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by OR EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE id = auth.uid() 
    AND role = 'manager'
  ));

-- Create goal_updates table
CREATE TABLE goal_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals(id) NOT NULL,
  created_by uuid REFERENCES user_profiles(id) NOT NULL,
  update_text text NOT NULL,
  progress_type text NOT NULL CHECK (progress_type IN ('improvement', 'setback', 'neutral')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE goal_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can read goal updates"
  ON goal_updates
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create goal updates"
  ON goal_updates
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Insert test clients
INSERT INTO clients (label) VALUES
  ('John Doe'),
  ('Jane Smith'),
  ('Robert Johnson'),
  ('Maria Garcia')
ON CONFLICT (id) DO NOTHING;