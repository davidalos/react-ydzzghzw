/*
  # Fix database policies

  1. Changes
    - Safely add policies using DO blocks to check existence first
    - Fix user role policies
    - Add missing policies
*/

DO $$ 
BEGIN
  -- Add policies for user_profiles if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' AND policyname = 'Users can read own profile'
  ) THEN
    CREATE POLICY "Users can read own profile"
      ON user_profiles
      FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile"
      ON user_profiles
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' AND policyname = 'Users can insert own profile'
  ) THEN
    CREATE POLICY "Users can insert own profile"
      ON user_profiles
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  -- Add policies for incidents if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incidents' AND policyname = 'Users can read own incidents'
  ) THEN
    CREATE POLICY "Users can read own incidents"
      ON incidents
      FOR SELECT
      TO authenticated
      USING (submitted_by = auth.uid() OR EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      ));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'incidents' AND policyname = 'Users can create incidents'
  ) THEN
    CREATE POLICY "Users can create incidents"
      ON incidents
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = submitted_by);
  END IF;

  -- Add policies for goals if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'goals' AND policyname = 'All authenticated users can read goals'
  ) THEN
    CREATE POLICY "All authenticated users can read goals"
      ON goals
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'goals' AND policyname = 'Users can create goals'
  ) THEN
    CREATE POLICY "Users can create goals"
      ON goals
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = created_by);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'goals' AND policyname = 'Users can update own goals'
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

  -- Add policies for goal_updates if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'goal_updates' AND policyname = 'All authenticated users can read goal updates'
  ) THEN
    CREATE POLICY "All authenticated users can read goal updates"
      ON goal_updates
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'goal_updates' AND policyname = 'Users can create goal updates'
  ) THEN
    CREATE POLICY "Users can create goal updates"
      ON goal_updates
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = created_by);
  END IF;
END $$;