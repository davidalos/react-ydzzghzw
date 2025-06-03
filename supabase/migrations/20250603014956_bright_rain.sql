/*
  # Initial Schema Setup

  1. New Tables
    - `user_profiles`
      - `id` (uuid, primary key) - matches auth.users.id
      - `full_name` (text)
      - `role` (text) - either 'employee' or 'manager'
      - `created_at` (timestamp)
    
    - `clients`
      - `id` (uuid, primary key)
      - `label` (text) - client identifier/name
      - `created_at` (timestamp)
    
    - `incidents`
      - `id` (uuid, primary key)
      - `client_id` (uuid, foreign key to clients)
      - `submitted_by` (uuid, foreign key to user_profiles)
      - `category` (text)
      - `description` (text)
      - `reflection` (text)
      - `serious` (boolean)
      - `co_staff` (text[])
      - `created_at` (timestamp)
    
    - `goals`
      - `id` (uuid, primary key)
      - `client_id` (uuid, foreign key to clients)
      - `created_by` (uuid, foreign key to user_profiles)
      - `title` (text)
      - `description` (text)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `goal_updates`
      - `id` (uuid, primary key)
      - `goal_id` (uuid, foreign key to goals)
      - `created_by` (uuid, foreign key to user_profiles)
      - `update_text` (text)
      - `progress_type` (text)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Managers can read all data
    - Employees can only read their own submissions
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
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
CREATE TABLE IF NOT EXISTS clients (
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
CREATE TABLE IF NOT EXISTS incidents (
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
CREATE TABLE IF NOT EXISTS goals (
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
CREATE TABLE IF NOT EXISTS goal_updates (
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