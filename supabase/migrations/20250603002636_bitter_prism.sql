/*
  # Add INSERT policy for user profiles

  1. Security Changes
    - Add RLS policy to allow users to insert their own profile data
    - Policy ensures users can only create a profile with their own user ID
*/

CREATE POLICY "Users can insert their own profile"
  ON public.user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);