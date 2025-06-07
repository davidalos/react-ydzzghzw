/*
  # KEYBRIDGE Final Platform Sync

  1. Database Schema Validation
    - Ensure all tables have proper RLS policies
    - Validate foreign key constraints
    - Add missing indexes for performance

  2. Security Enhancements
    - Strengthen RLS policies for data privacy
    - Add audit logging for sensitive operations
    - Implement GDPR compliance functions

  3. Data Integrity
    - Add validation constraints
    - Create data cleanup functions
    - Ensure proper user profile handling
*/

-- Ensure all tables have RLS enabled
ALTER TABLE IF EXISTS clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS goal_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS role_change_log ENABLE ROW LEVEL SECURITY;

-- Fix user_profiles table structure
DO $$
BEGIN
  -- Ensure user_profiles has all required columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'full_name'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN full_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'role'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN role text DEFAULT 'employee';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Ensure proper foreign key relationships
DO $$
BEGIN
  -- Add foreign key to auth.users if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'user_profiles_id_fkey'
  ) THEN
    ALTER TABLE user_profiles 
    ADD CONSTRAINT user_profiles_id_fkey 
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add performance indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_incidents_client ON incidents(client_id);
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_by ON incidents(submitted_by);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_serious ON incidents(serious) WHERE serious = true;
CREATE INDEX IF NOT EXISTS idx_goals_client ON goals(client_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_created_by ON goals(created_by);
CREATE INDEX IF NOT EXISTS idx_goal_updates_goal ON goal_updates(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_updates_created_by ON goal_updates(created_by);

-- Ensure proper data validation constraints
DO $$
BEGIN
  -- User profile role validation
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'user_profiles_role_check'
  ) THEN
    ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check 
    CHECK (role IN ('employee', 'manager'));
  END IF;

  -- Incident category validation
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'incidents_category_check'
  ) THEN
    ALTER TABLE incidents ADD CONSTRAINT incidents_category_check 
    CHECK (category IN ('Positive Progress', 'Medical', 'Behavioral', 'Safety', 'Emergency'));
  END IF;

  -- Goal status validation
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'goals_status_check'
  ) THEN
    ALTER TABLE goals ADD CONSTRAINT goals_status_check 
    CHECK (status IN ('active', 'completed', 'archived'));
  END IF;

  -- Goal update progress type validation
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'goal_updates_progress_type_check'
  ) THEN
    ALTER TABLE goal_updates ADD CONSTRAINT goal_updates_progress_type_check 
    CHECK (progress_type IN ('improvement', 'setback', 'neutral'));
  END IF;
END $$;

-- Create or update RLS policies for maximum security
DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;
CREATE POLICY "Users can read own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND 
    role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "Managers can update any profile" ON user_profiles;
CREATE POLICY "Managers can update any profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role = 'manager'
    )
  );

-- Incident access policies
DROP POLICY IF EXISTS "Users can create incidents" ON incidents;
CREATE POLICY "Users can create incidents"
  ON incidents
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = submitted_by);

DROP POLICY IF EXISTS "Users can read relevant incidents" ON incidents;
CREATE POLICY "Users can read relevant incidents"
  ON incidents
  FOR SELECT
  TO authenticated
  USING (
    submitted_by = auth.uid() OR 
    auth.uid() = ANY(co_staff) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role = 'manager'
    )
  );

-- Goal access policies
DROP POLICY IF EXISTS "Users can create goals" ON goals;
CREATE POLICY "Users can create goals"
  ON goals
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "All authenticated users can read goals" ON goals;
CREATE POLICY "All authenticated users can read goals"
  ON goals
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own goals or managers can update any" ON goals;
CREATE POLICY "Users can update own goals or managers can update any"
  ON goals
  FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role = 'manager'
    )
  );

-- Goal updates policies
DROP POLICY IF EXISTS "Users can create goal updates" ON goal_updates;
CREATE POLICY "Users can create goal updates"
  ON goal_updates
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "All authenticated users can read goal updates" ON goal_updates;
CREATE POLICY "All authenticated users can read goal updates"
  ON goal_updates
  FOR SELECT
  TO authenticated
  USING (true);

-- Client access policies
DROP POLICY IF EXISTS "All authenticated users can read clients" ON clients;
CREATE POLICY "All authenticated users can read clients"
  ON clients
  FOR SELECT
  TO authenticated
  USING (true);

-- Role change log policies
DROP POLICY IF EXISTS "Managers can view all role changes" ON role_change_log;
CREATE POLICY "Managers can view all role changes"
  ON role_change_log
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role = 'manager'
    )
  );

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'employee')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function for role change logging
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO role_change_log (user_id, old_role, new_role, changed_by)
    VALUES (NEW.id, OLD.role, NEW.role, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role change logging
DROP TRIGGER IF EXISTS log_role_changes ON user_profiles;
CREATE TRIGGER log_role_changes
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION log_role_change();

-- Create function for data cleanup (GDPR compliance)
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
  -- Clean up old audit logs (keep for 2 years)
  DELETE FROM role_change_log 
  WHERE changed_at < now() - interval '2 years';
  
  -- Log cleanup action
  RAISE NOTICE 'Cleaned up old audit logs older than 2 years';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create manager dashboard view with proper security
CREATE OR REPLACE VIEW manager_dashboard_stats AS
SELECT 
  COUNT(*) FILTER (WHERE created_at >= current_date - interval '7 days') as incidents_this_week,
  COUNT(*) FILTER (WHERE created_at >= current_date - interval '30 days') as incidents_this_month,
  COUNT(*) FILTER (WHERE serious = true) as serious_incidents,
  COUNT(DISTINCT client_id) as unique_clients_affected
FROM incidents
WHERE EXISTS (
  SELECT 1 FROM user_profiles 
  WHERE id = auth.uid() AND role = 'manager'
);

-- Grant access to the view
GRANT SELECT ON manager_dashboard_stats TO authenticated;

-- Ensure RLS is enabled on the view
ALTER VIEW manager_dashboard_stats SET (security_barrier = true);