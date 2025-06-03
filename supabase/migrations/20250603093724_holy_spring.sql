/*
  # Fix duplicate policies

  1. Changes
    - Drop all existing policies before recreating them
    - Ensure clean policy setup without duplicates
    
  2. Security
    - Maintain existing security model
    - Keep all necessary policies for proper access control
*/

-- Drop all existing policies first
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
  DROP POLICY IF EXISTS "user_profile_self_update_v3" ON public.user_profiles;
  DROP POLICY IF EXISTS "manager_profile_update_v3" ON public.user_profiles;
  DROP POLICY IF EXISTS "All authenticated users can read clients" ON public.clients;
  DROP POLICY IF EXISTS "Users can create incidents" ON public.incidents;
  DROP POLICY IF EXISTS "Users can read own incidents" ON public.incidents;
  DROP POLICY IF EXISTS "All authenticated users can read goals" ON public.goals;
  DROP POLICY IF EXISTS "Users can create goals" ON public.goals;
  DROP POLICY IF EXISTS "Users can update own goals" ON public.goals;
  DROP POLICY IF EXISTS "All authenticated users can read goal updates" ON public.goal_updates;
  DROP POLICY IF EXISTS "Users can create goal updates" ON public.goal_updates;
END $$;

-- Recreate all policies
CREATE POLICY "Users can read own profile"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "user_profile_self_update_v3"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "manager_profile_update_v3"
  ON public.user_profiles
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

CREATE POLICY "All authenticated users can read clients"
  ON public.clients
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create incidents"
  ON public.incidents
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = submitted_by);

CREATE POLICY "Users can read own incidents"
  ON public.incidents
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

CREATE POLICY "All authenticated users can read goals"
  ON public.goals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create goals"
  ON public.goals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own goals"
  ON public.goals
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

CREATE POLICY "All authenticated users can read goal updates"
  ON public.goal_updates
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create goal updates"
  ON public.goal_updates
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);