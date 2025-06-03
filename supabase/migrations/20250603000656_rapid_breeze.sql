/*
  # Create test manager user

  1. Changes
    - Creates a test user account if it doesn't exist
    - Adds corresponding user profile with manager role
  
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

    -- Add user profile with manager role
    INSERT INTO public.user_profiles (id, role, full_name)
    VALUES (new_user_id, 'manager', 'Test Manager');
  END IF;
END $$;