/*
  # KEYBRIDGE Final Sync Migration - Fixed

  1. Data Cleanup
    - Remove orphaned incidents with invalid client_id references
  
  2. Foreign Key Constraints
    - Add incidents_client_id_fkey constraint safely
  
  3. Performance Indexes
    - Add optimized indexes for better query performance
  
  4. RLS Policies
    - Ensure all policies exist without conflicts
    - Enable RLS on all tables
  
  5. Data Validation
    - Insert test data to verify schema integrity
*/

-- Step 1: Clean up orphaned data before adding constraints
DELETE FROM public.incidents 
WHERE client_id IS NOT NULL
  AND client_id NOT IN (SELECT id FROM public.clients);

-- Step 2: Add foreign key constraint with proper error handling
DO $$
BEGIN
  -- Check if constraint already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'incidents_client_id_fkey'
  ) THEN
    ALTER TABLE public.incidents 
    ADD CONSTRAINT incidents_client_id_fkey 
    FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Step 3: Add performance indexes
CREATE INDEX IF NOT EXISTS idx_incidents_client_id ON public.incidents(client_id);
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_by ON public.incidents(submitted_by);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON public.incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_serious ON public.incidents(serious) WHERE serious = true;

-- Step 4: Add indexes for other tables
CREATE INDEX IF NOT EXISTS idx_clients_label ON public.clients(label);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_goals_status ON public.goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_client_id ON public.goals(client_id);
CREATE INDEX IF NOT EXISTS idx_goal_updates_goal_id ON public.goal_updates(goal_id);

-- Step 5: Handle policy conflicts safely
DO $$
BEGIN
  -- Only create policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'role_change_log' 
    AND policyname = 'Managers can view all role changes'
  ) THEN
    CREATE POLICY "Managers can view all role changes"
      ON public.role_change_log
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM user_profiles
          WHERE user_profiles.id = auth.uid() 
          AND user_profiles.role = 'manager'
        )
      );
  END IF;
END $$;

-- Step 6: Ensure RLS is enabled on all tables
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_change_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_updates ENABLE ROW LEVEL SECURITY;

-- Step 7: Ensure clients table has proper policies
DO $$
BEGIN
  -- Add basic policy for clients if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'clients' 
    AND policyname = 'All authenticated users can read clients'
  ) THEN
    CREATE POLICY "All authenticated users can read clients"
      ON public.clients
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Step 8: Test data integrity
INSERT INTO public.clients (name, label) 
VALUES ('KEYBRIDGE Test Client', 'Test Validation') 
ON CONFLICT DO NOTHING;

-- Step 9: Verify foreign key relationships work
DO $$
DECLARE
  test_client_id uuid;
  test_user_id uuid;
BEGIN
  -- Get a test client ID
  SELECT id INTO test_client_id FROM public.clients LIMIT 1;
  
  -- Get a test user ID (if any exist)
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  -- Only insert test incident if we have both client and user
  IF test_client_id IS NOT NULL AND test_user_id IS NOT NULL THEN
    INSERT INTO public.incidents (client_id, submitted_by, category, description)
    VALUES (test_client_id, test_user_id, 'Safety', 'KEYBRIDGE migration test - safe to delete')
    ON CONFLICT DO NOTHING;
    
    -- Clean up test incident immediately
    DELETE FROM public.incidents 
    WHERE description = 'KEYBRIDGE migration test - safe to delete';
  END IF;
END $$;