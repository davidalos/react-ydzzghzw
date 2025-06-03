/*
  # Fix user_profiles policies

  1. Changes
    - Add safety checks before creating policies
    - Enable RLS if not already enabled
    - Create policies only if they don't exist

  2. Security
    - Maintains same security model as before
    - Ensures policies exist without causing errors
*/

DO $$ 
BEGIN
  -- Enable RLS if not already enabled
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
  END IF;

  -- Create insert policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles' 
    AND policyname = 'Users can insert their own profile'
  ) THEN
    CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);
  END IF;

  -- Create select policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles' 
    AND policyname = 'Users can read all profiles'
  ) THEN
    CREATE POLICY "Users can read all profiles"
    ON public.user_profiles
    FOR SELECT
    TO authenticated
    USING (true);
  END IF;

  -- Create update policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles' 
    AND policyname = 'Users can update their own profile'
  ) THEN
    CREATE POLICY "Users can update their own profile"
    ON public.user_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
  END IF;
END $$;