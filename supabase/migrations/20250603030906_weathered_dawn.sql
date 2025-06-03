/*
  # Fix database schema and policies

  1. Changes
    - Drop all existing tables to start fresh
    - Recreate tables with proper constraints and CASCADE rules
    - Add proper RLS policies
    - Fix foreign key references to use auth.users instead of user_profiles
    - Add proper indexes for performance
  
  2. Security
    - Enable RLS on all tables
    - Add proper policies for all operations
    - Ensure proper cascade rules for deletions
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS goal_updates CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'employee',
  created_at timestamptz DEFAULT now(),
  CONSTRAINT user_profiles_role_check CHECK (role IN ('employee', 'manager'))
);

CREATE INDEX idx_user_profiles_role ON user_profiles(role);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can read own profile"
    ON user_profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create clients table
CREATE TABLE clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_clients_label ON clients(label);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "All authenticated users can read clients"
    ON clients FOR SELECT
    TO authenticated
    USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create incidents table
CREATE TABLE incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  submitted_by uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category text NOT NULL,
  description text NOT NULL,
  reflection text,
  serious boolean DEFAULT false,
  co_staff text[],
  created_at timestamptz DEFAULT now(),
  CONSTRAINT incidents_category_check CHECK (category IN ('Positive Progress', 'Medical', 'Behavioral', 'Safety', 'Emergency'))
);

CREATE INDEX idx_incidents_client ON incidents(client_id);
CREATE INDEX idx_incidents_submitted_by ON incidents(submitted_by);
CREATE INDEX idx_incidents_created_at ON incidents(created_at DESC);

ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can read own incidents"
    ON incidents FOR SELECT
    TO authenticated
    USING (
      submitted_by = auth.uid() OR 
      EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      )
    );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can create incidents"
    ON incidents FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = submitted_by);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create goals table
CREATE TABLE goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  CONSTRAINT goals_status_check CHECK (status IN ('active', 'completed', 'archived'))
);

CREATE INDEX idx_goals_client ON goals(client_id);
CREATE INDEX idx_goals_created_by ON goals(created_by);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_created_at ON goals(created_at DESC);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "All authenticated users can read goals"
    ON goals FOR SELECT
    TO authenticated
    USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can create goals"
    ON goals FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own goals"
    ON goals FOR UPDATE
    TO authenticated
    USING (
      auth.uid() = created_by OR 
      EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      )
    );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create goal_updates table
CREATE TABLE goal_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals(id) ON DELETE CASCADE NOT NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  update_text text NOT NULL,
  progress_type text NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT goal_updates_progress_type_check CHECK (progress_type IN ('improvement', 'setback', 'neutral'))
);

CREATE INDEX idx_goal_updates_goal ON goal_updates(goal_id);
CREATE INDEX idx_goal_updates_created_by ON goal_updates(created_by);
CREATE INDEX idx_goal_updates_created_at ON goal_updates(created_at DESC);

ALTER TABLE goal_updates ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "All authenticated users can read goal updates"
    ON goal_updates FOR SELECT
    TO authenticated
    USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can create goal updates"
    ON goal_updates FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Insert test clients
INSERT INTO clients (label) VALUES
  ('John Doe'),
  ('Jane Smith'),
  ('Robert Johnson'),
  ('Maria Garcia')
ON CONFLICT (label) DO NOTHING;