/*
  # Security Improvements

  1. Changes
    - Fix anonymous access policies by requiring authentication
    - Add search_path to function
    - Add missing policies for authenticated users
    
  2. Security
    - Ensure all policies require authentication
    - Prevent anonymous access
    - Set explicit search paths
*/

-- Set search_path for function to prevent search_path injection
ALTER FUNCTION public.handle_new_user SET search_path = public;

-- Update policies to explicitly require authenticated users
ALTER POLICY "All authenticated users can read clients" 
  ON public.clients
  USING (auth.role() = 'authenticated');

ALTER POLICY "All authenticated users can read goals" 
  ON public.goals
  USING (auth.role() = 'authenticated');

ALTER POLICY "All authenticated users can read goal updates" 
  ON public.goal_updates
  USING (auth.role() = 'authenticated');

ALTER POLICY "Users can read own profile" 
  ON public.user_profiles
  USING (auth.role() = 'authenticated' AND auth.uid() = id);

ALTER POLICY "Users can read own incidents" 
  ON public.incidents
  USING (
    auth.role() = 'authenticated' AND (
      submitted_by = auth.uid() OR 
      EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      )
    )
  );


-- Add explicit INSERT policies with authentication checks
ALTER POLICY "Users can create incidents" 
  ON public.incidents
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = submitted_by);

ALTER POLICY "Users can create goals" 
  ON public.goals
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = created_by);

ALTER POLICY "Users can create goal updates" 
  ON public.goal_updates
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = created_by);

-- Add explicit UPDATE policies with authentication checks
ALTER POLICY "Users can update own goals" 
  ON public.goals
  WITH CHECK (
    auth.role() = 'authenticated' AND (
      created_by = auth.uid() OR 
      EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() 
        AND role = 'manager'
      )
    )
  );

ALTER POLICY "user_profile_self_update_v3" 
  ON public.user_profiles
  WITH CHECK (
    auth.role() = 'authenticated' AND
    auth.uid() = id AND
    role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

ALTER POLICY "manager_profile_update_v3" 
  ON public.user_profiles
  WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );