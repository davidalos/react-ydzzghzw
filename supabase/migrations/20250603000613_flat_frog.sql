/*
  # Create test user with manager role

  1. New User
    - Creates a test user account with manager role
    - Email: test@example.com
    - Password: test123 (for development only)

  2. Security
    - Adds user profile
    - Sets manager role
*/

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
);

-- Add user profile with manager role
INSERT INTO public.user_profiles (id, role, full_name)
SELECT id, 'manager', 'Test Manager'
FROM auth.users
WHERE email = 'test@example.com';