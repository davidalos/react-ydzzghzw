/*
  # Update database policies and constraints

  This migration safely adds or updates:
  1. Row Level Security policies
  2. Column constraints
  3. Foreign key relationships
  
  It uses IF NOT EXISTS checks to avoid conflicts with existing objects.
*/

-- Enable RLS on all tables if not already enabled
ALTER TABLE IF EXISTS user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS goal_updates ENABLE ROW LEVEL SECURITY;

-- Add or update policies for user_profiles
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can read own profile'
  ) THEN
    CREATE POLICY "Users can read own profile"
      ON user_profiles
      FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile"
      ON user_profiles
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = id);
  END IF;
END $$;

-- Add or update policies for clients
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clients' AND policyname = 'All authenticated users can read clients'
  ) THEN
    CREATE POLICY "All authenticated users can read clients"
      ON clients
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Add or update policies for incidents
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'incidents' AND policyname = 'Employees can read own incidents'
  ) THEN
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
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'incidents' AND policyname = 'Users can create incidents'
  ) THEN
    CREATE POLICY "Users can create incidents"
      ON incidents
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = submitted_by);
  END IF;
END $$;

-- Add or update policies for goals
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'All authenticated users can read goals'
  ) THEN
    CREATE POLICY "All authenticated users can read goals"
      ON goals
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'Users can create goals'
  ) THEN
    CREATE POLICY "Users can create goals"
      ON goals
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = created_by);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'Users can update own goals'
  ) THEN
    CREATE POLICY "Users can update own goals"
      ON goals
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = created_by OR EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      ));
  END IF;
END $$;

-- Add or update policies for goal_updates
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_updates' AND policyname = 'All authenticated users can read goal updates'
  ) THEN
    CREATE POLICY "All authenticated users can read goal updates"
      ON goal_updates
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goal_updates' AND policyname = 'Users can create goal updates'
  ) THEN
    CREATE POLICY "Users can create goal updates"
      ON goal_updates
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = created_by);
  END IF;
END $$;

-- Ensure constraints exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'user_profiles' AND constraint_name = 'user_profiles_role_check'
  ) THEN
    ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check 
      CHECK (role IN ('employee', 'manager'));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'goals' AND constraint_name = 'goals_status_check'
  ) THEN
    ALTER TABLE goals ADD CONSTRAINT goals_status_check 
      CHECK (status IN ('active', 'completed', 'archived'));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'goal_updates' AND constraint_name = 'goal_updates_progress_type_check'
  ) THEN
    ALTER TABLE goal_updates ADD CONSTRAINT goal_updates_progress_type_check 
      CHECK (progress_type IN ('improvement', 'setback', 'neutral'));
  END IF;
END $$;