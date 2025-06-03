/*
  # Update user roles system

  1. Changes
    - Drop existing role-related policies
    - Create new simplified role system
    - Set default role to 'employee'
    - Add policies for role management
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can read own role" ON public.user_profiles;
END $$;

-- Ensure the user_role type exists
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

-- Update user_profiles table
ALTER TABLE public.user_profiles 
ALTER COLUMN role SET DEFAULT 'employee'::user_role;

-- Create new policies
CREATE POLICY "Users can read own role"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;