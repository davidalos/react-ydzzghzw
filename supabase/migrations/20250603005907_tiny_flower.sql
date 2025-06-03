/*
  # Add manager role to user_profiles table

  This migration ensures the user_profiles table has the correct role type and adds necessary policies.
*/

-- Check if the role type exists and create it if it doesn't
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_type 
    WHERE typname = 'user_role'
  ) THEN
    CREATE TYPE user_role AS ENUM ('employee', 'manager');
  END IF;
END $$;

-- Add role column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'user_profiles' 
    AND column_name = 'role'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN role user_role NOT NULL DEFAULT 'employee';
  END IF;
END $$;

-- Ensure RLS is enabled
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create or replace policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_profiles' 
    AND policyname = 'Users can read own role'
  ) THEN
    CREATE POLICY "Users can read own role"
    ON public.user_profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);
  END IF;
END $$;