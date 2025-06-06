/*
  # Complete Schema Setup
  
  1. Tables
    - user_profiles (with role management)
    - clients
    - incidents (with category management)
    - goals (with status tracking)
    - goal_updates (with progress tracking)
    
  2. Security
    - RLS enabled on all tables
    - Appropriate policies for each table
    
  3. Performance
    - Indexes on frequently queried columns
*/

-- Drop all existing policies first
DO $$
BEGIN
  IF to_regclass('public.user_profiles') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
    DROP POLICY IF EXISTS "user_profile_self_update_v3" ON public.user_profiles;
    DROP POLICY IF EXISTS "manager_profile_update_v3" ON public.user_profiles;
  END IF;

  IF to_regclass('public.clients') IS NOT NULL THEN
    DROP POLICY IF EXISTS "All authenticated users can read clients" ON public.clients;
  END IF;

  IF to_regclass('public.incidents') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Users can create incidents" ON public.incidents;
    DROP POLICY IF EXISTS "Users can read own incidents" ON public.incidents;
  END IF;

  IF to_regclass('public.goals') IS NOT NULL THEN
    DROP POLICY IF EXISTS "All authenticated users can read goals" ON public.goals;
    DROP POLICY IF EXISTS "Users can create goals" ON public.goals;
    DROP POLICY IF EXISTS "Users can update own goals" ON public.goals;
  END IF;

  IF to_regclass('public.goal_updates') IS NOT NULL THEN
    DROP POLICY IF EXISTS "All authenticated users can read goal updates" ON public.goal_updates;
    DROP POLICY IF EXISTS "Users can create goal updates" ON public.goal_updates;
  END IF;
END $$;

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'employee',
  created_at timestamptz DEFAULT now(),
  CONSTRAINT user_profiles_role_check CHECK (role IN ('employee', 'manager'))
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "user_profile_self_update_v3"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "manager_profile_update_v3"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );

-- Create clients table
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL UNIQUE,
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
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  submitted_by uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  category text NOT NULL,
  description text NOT NULL,
  reflection text,
  serious boolean DEFAULT false,
  co_staff text[],
  created_at timestamptz DEFAULT now(),
  CONSTRAINT incidents_category_check CHECK (category IN ('Positive Progress', 'Medical', 'Behavioral', 'Safety', 'Emergency'))
);

ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create incidents"
  ON incidents
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = submitted_by);

CREATE POLICY "Users can read own incidents"
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

-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  CONSTRAINT goals_status_check CHECK (status IN ('active', 'completed', 'archived'))
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
  USING (
    created_by = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() 
      AND role = 'manager'
    )
  );

-- Create goal_updates table
CREATE TABLE IF NOT EXISTS goal_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  update_text text NOT NULL,
  progress_type text NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT goal_updates_progress_type_check CHECK (progress_type IN ('improvement', 'setback', 'neutral'))
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_incidents_client ON incidents(client_id);
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_by ON incidents(submitted_by);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incidents(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_goals_client ON goals(client_id);
CREATE INDEX IF NOT EXISTS idx_goals_created_by ON goals(created_by);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_created_at ON goals(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_goal_updates_goal ON goal_updates(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_updates_created_by ON goal_updates(created_by);
CREATE INDEX IF NOT EXISTS idx_goal_updates_created_at ON goal_updates(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_clients_label ON clients(label);