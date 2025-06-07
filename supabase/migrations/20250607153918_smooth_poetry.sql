/*
  # KEYBRIDGE_SYNC_V10: Final Database Synchronization

  1. Policy Conflict Resolution
    - Check and handle existing policies safely
    - Avoid duplicate policy creation

  2. Data Cleanup
    - Remove orphaned incident records
    - Ensure referential integrity

  3. Constraint Management
    - Add foreign key constraints safely
    - Use proper PostgreSQL syntax for conditional operations

  4. Performance Optimization
    - Add necessary indexes
    - Optimize query performance
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

-- Step 3: Add co_staff array constraint with proper syntax
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'incidents_co_staff_is_array'
  ) THEN
    ALTER TABLE public.incidents 
    ADD CONSTRAINT incidents_co_staff_is_array 
    CHECK (co_staff IS NULL OR jsonb_typeof(co_staff) = 'array');
  END IF;
END $$;

-- Step 4: Add performance indexes
CREATE INDEX IF NOT EXISTS idx_incidents_client_id ON public.incidents(client_id);
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON public.incidents USING GIN(co_staff);

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

-- Step 7: Test data integrity
INSERT INTO public.clients (name, label) 
VALUES ('KEYBRIDGE Test Client', 'Test Validation') 
ON CONFLICT DO NOTHING;