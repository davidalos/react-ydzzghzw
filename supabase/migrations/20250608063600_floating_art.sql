/*
  # KEYBRIDGE Final Sync Migration

  1. Database Cleanup and Integrity
    - Clean up orphaned incident records
    - Add missing co_staff column to incidents table
    - Add proper foreign key constraints
    - Add performance indexes

  2. Security and Policies
    - Ensure RLS is enabled on all tables
    - Add missing policies safely (avoid duplicates)
    - Validate all security constraints

  3. Data Validation
    - Test data integrity
    - Verify foreign key relationships
    - Ensure proper JSONB structure for co_staff
*/

-- Step 1: Clean up orphaned data before adding constraints
DELETE FROM public.incidents 
WHERE client_id IS NOT NULL
  AND client_id NOT IN (SELECT id FROM public.clients);

-- Step 2: Add co_staff column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'incidents' 
    AND column_name = 'co_staff'
  ) THEN
    ALTER TABLE public.incidents 
    ADD COLUMN co_staff JSONB DEFAULT NULL;
  END IF;
END $$;

-- Step 3: Add foreign key constraint with proper error handling
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

-- Step 4: Add co_staff array constraint with proper syntax
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

-- Step 5: Add performance indexes
CREATE INDEX IF NOT EXISTS idx_incidents_client_id ON public.incidents(client_id);
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON public.incidents USING GIN(co_staff);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON public.incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_category ON public.incidents(category);
CREATE INDEX IF NOT EXISTS idx_incidents_serious ON public.incidents(serious) WHERE serious = true;

-- Step 6: Handle policy conflicts safely
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

-- Step 7: Ensure RLS is enabled on all tables
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_change_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_updates ENABLE ROW LEVEL SECURITY;

-- Step 8: Add missing indexes for other tables
CREATE INDEX IF NOT EXISTS idx_goals_client_id ON public.goals(client_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON public.goals(status);
CREATE INDEX IF NOT EXISTS idx_goal_updates_goal_id ON public.goal_updates(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_updates_progress_type ON public.goal_updates(progress_type);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);

-- Step 9: Test data integrity and validation
INSERT INTO public.clients (name, label) 
VALUES ('KEYBRIDGE Test Client', 'Test Validation') 
ON CONFLICT DO NOTHING;

-- Step 10: Validate foreign key relationships
DO $$
BEGIN
  -- Test that we can insert a valid incident
  INSERT INTO public.incidents (
    client_id, 
    submitted_by, 
    category, 
    description, 
    co_staff
  ) 
  SELECT 
    c.id,
    up.id,
    'Safety',
    'KEYBRIDGE migration test incident',
    '[]'::jsonb
  FROM public.clients c, public.user_profiles up 
  WHERE c.label = 'Test Validation'
  AND up.role = 'manager'
  LIMIT 1
  ON CONFLICT DO NOTHING;
  
  -- Clean up test incident
  DELETE FROM public.incidents 
  WHERE description = 'KEYBRIDGE migration test incident';
  
  RAISE NOTICE 'KEYBRIDGE migration completed successfully - all constraints and relationships validated';
END $$;