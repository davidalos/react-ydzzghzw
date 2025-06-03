/*
  # Fix RLS policies for user profiles

  1. Changes
    - Add policy to allow authenticated users to insert their own profile
    - Add policy to allow authenticated users to read all profiles
    - Add policy to allow authenticated users to update their own profile

  2. Security
    - Ensures users can only manage their own profiles
    - Allows reading of all profiles for user display
*/

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Allow users to read all profiles
CREATE POLICY "Users can read all profiles"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);