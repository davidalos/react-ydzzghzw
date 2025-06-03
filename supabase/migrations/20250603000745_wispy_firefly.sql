/*
  # Create test user with manager role

  1. Changes
    - Creates a test user if it doesn't exist
    - Creates a user profile with manager role if it doesn't exist
    
  2. Security
    - Checks for existing records before insertion
    - Uses safe password hashing
*/

DO $$
DECLARE
  new_user_id uuid;
BEGIN
  -- Only create user if email doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'test@example.com'
  ) THEN
    -- Create the user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'test@example.com',
      crypt('test123', gen_salt('bf')),
      now(),
      now(),
      now()
    ) RETURNING id INTO new_user_id;

    -- Only create profile if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM public.user_profiles WHERE id = new_user_id
    ) THEN
      INSERT INTO public.user_profiles (id, role, full_name)
      VALUES (new_user_id, 'manager', 'Test Manager');
    END IF;
  END IF;
END $$;