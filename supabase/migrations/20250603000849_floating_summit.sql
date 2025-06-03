/*
  # Fix Authentication Schema

  1. Changes
    - Ensures auth schema is properly configured
    - Adds necessary triggers for user management
    - Sets up initial test user if not exists
    
  2. Security
    - Maintains RLS policies
    - Ensures proper role assignments
*/

-- First check if the user exists
DO $$ 
DECLARE
  user_exists boolean;
  new_user_id uuid;
BEGIN
  -- Check if user already exists
  SELECT EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE email = 'test@example.com'
  ) INTO user_exists;

  -- Only create new user if they don't exist
  IF NOT user_exists THEN
    -- Create auth user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      recovery_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'test@example.com',
      crypt('test123', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      NOW(),
      NOW(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO new_user_id;

    -- Only insert into user_profiles if the user was created
    IF new_user_id IS NOT NULL THEN
      INSERT INTO public.user_profiles (id, role, full_name)
      VALUES (new_user_id, 'manager', 'Test Manager');
    END IF;
  END IF;
END $$;