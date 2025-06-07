/*
  # Seed Sample Data for Atvikaskráning

  1. Sample Data
    - Creates 6 sample clients (Íbúar 1-6)
    - Adds 15 varied incidents across all categories
    - Creates 6 goals with different statuses
    - Adds goal updates showing progress tracking

  2. Data Safety
    - Uses conditional inserts to avoid duplicates
    - Creates realistic sample data in Icelandic
    - Maintains referential integrity
*/

-- Insert sample clients if they don't exist
DO $$
DECLARE
  client_count integer;
BEGIN
  -- Check if we already have clients
  SELECT COUNT(*) INTO client_count FROM clients;
  
  -- Only insert if we have fewer than 6 clients
  IF client_count < 6 THEN
    -- Insert clients that don't exist
    INSERT INTO clients (label) 
    SELECT unnest(ARRAY['Íbúi 1', 'Íbúi 2', 'Íbúi 3', 'Íbúi 4', 'Íbúi 5', 'Íbúi 6'])
    WHERE NOT EXISTS (
      SELECT 1 FROM clients WHERE label = unnest(ARRAY['Íbúi 1', 'Íbúi 2', 'Íbúi 3', 'Íbúi 4', 'Íbúi 5', 'Íbúi 6'])
    );
  END IF;
END $$;

-- Create sample user profile if it doesn't exist
DO $$
DECLARE
  sample_user_id uuid := '00000000-0000-0000-0000-000000000001';
  user_exists boolean;
BEGIN
  -- Check if sample user exists in auth.users (we can't insert there directly)
  -- Instead, we'll use the first real user or create a placeholder
  SELECT EXISTS(SELECT 1 FROM user_profiles LIMIT 1) INTO user_exists;
  
  -- If no users exist, we'll skip the data seeding for now
  -- This will be populated when real users sign up
  IF NOT user_exists THEN
    RAISE NOTICE 'No users found - sample data will be created when users sign up';
    RETURN;
  END IF;
END $$;

-- Insert sample data using existing users
DO $$
DECLARE
  client1_id uuid;
  client2_id uuid;
  client3_id uuid;
  client4_id uuid;
  client5_id uuid;
  client6_id uuid;
  sample_user_id uuid;
  incident_count integer;
  goal_count integer;
BEGIN
  -- Get the first available user
  SELECT id INTO sample_user_id FROM user_profiles LIMIT 1;
  
  -- If no users exist, skip seeding
  IF sample_user_id IS NULL THEN
    RAISE NOTICE 'No user profiles found - skipping sample data creation';
    RETURN;
  END IF;

  -- Get client IDs
  SELECT id INTO client1_id FROM clients WHERE label = 'Íbúi 1' LIMIT 1;
  SELECT id INTO client2_id FROM clients WHERE label = 'Íbúi 2' LIMIT 1;
  SELECT id INTO client3_id FROM clients WHERE label = 'Íbúi 3' LIMIT 1;
  SELECT id INTO client4_id FROM clients WHERE label = 'Íbúi 4' LIMIT 1;
  SELECT id INTO client5_id FROM clients WHERE label = 'Íbúi 5' LIMIT 1;
  SELECT id INTO client6_id FROM clients WHERE label = 'Íbúi 6' LIMIT 1;

  -- Check if we already have sample incidents
  SELECT COUNT(*) INTO incident_count FROM incidents;
  
  -- Only insert incidents if we have fewer than 10
  IF incident_count < 10 THEN
    -- Insert sample incidents with varied dates and categories
    INSERT INTO incidents (client_id, submitted_by, category, description, serious, created_at) VALUES
      (client1_id, sample_user_id, 'Positive Progress', 'Íbúi sýndi frábæra framfarir í samskiptum í dag', false, NOW() - INTERVAL '1 day'),
      (client2_id, sample_user_id, 'Medical', 'Regluleg lyfjataka, engar aukaverkanir', false, NOW() - INTERVAL '2 days'),
      (client3_id, sample_user_id, 'Behavioral', 'Smá erfiðleikar við morgunrútínu', false, NOW() - INTERVAL '3 days'),
      (client1_id, sample_user_id, 'Safety', 'Öryggisathugun framkvæmd', false, NOW() - INTERVAL '4 days'),
      (client4_id, sample_user_id, 'Positive Progress', 'Náði markmiði sínu í þjálfun', false, NOW() - INTERVAL '5 days'),
      (client2_id, sample_user_id, 'Medical', 'Læknisheimsókn fór vel', false, NOW() - INTERVAL '6 days'),
      (client5_id, sample_user_id, 'Behavioral', 'Góð samvinna við starfsfólk', false, NOW() - INTERVAL '7 days'),
      (client6_id, sample_user_id, 'Emergency', 'Smávægilegur slys, vel meðhöndlað', true, NOW() - INTERVAL '8 days'),
      (client3_id, sample_user_id, 'Positive Progress', 'Sjálfstæði í daglegum verkefnum aukist', false, NOW() - INTERVAL '9 days'),
      (client4_id, sample_user_id, 'Medical', 'Heilsufarsmat framkvæmt', false, NOW() - INTERVAL '10 days'),
      (client1_id, sample_user_id, 'Safety', 'Öryggisbúnaður uppfærður', false, NOW() - INTERVAL '11 days'),
      (client5_id, sample_user_id, 'Positive Progress', 'Frábær þátttaka í hópstarfi', false, NOW() - INTERVAL '12 days'),
      (client2_id, sample_user_id, 'Behavioral', 'Jákvæð hegðunarbreyting', false, NOW() - INTERVAL '13 days'),
      (client6_id, sample_user_id, 'Medical', 'Regluleg heilsufarsskoðun', false, NOW() - INTERVAL '14 days'),
      (client3_id, sample_user_id, 'Positive Progress', 'Náði persónulegu markmiði', false, NOW() - INTERVAL '15 days');
  END IF;

  -- Check if we already have sample goals
  SELECT COUNT(*) INTO goal_count FROM goals;
  
  -- Only insert goals if we have fewer than 5
  IF goal_count < 5 THEN
    -- Insert sample goals
    INSERT INTO goals (client_id, created_by, title, description, status, created_at) VALUES
      (client1_id, sample_user_id, 'Bæta samskiptahæfni', 'Vinna að því að bæta munnlega samskipti', 'active', NOW() - INTERVAL '30 days'),
      (client2_id, sample_user_id, 'Sjálfstæði í daglegum verkefnum', 'Auka sjálfstæði við persónulega umhirðu', 'active', NOW() - INTERVAL '25 days'),
      (client3_id, sample_user_id, 'Félagsleg þátttaka', 'Taka þátt í fleiri félagslegum athöfnum', 'active', NOW() - INTERVAL '20 days'),
      (client4_id, sample_user_id, 'Líkamsrækt og heilsa', 'Viðhalda reglulegri líkamsrækt', 'completed', NOW() - INTERVAL '45 days'),
      (client5_id, sample_user_id, 'Læsi og skrift', 'Bæta lestrar- og skriftarhæfni', 'active', NOW() - INTERVAL '35 days'),
      (client6_id, sample_user_id, 'Tækninotkun', 'Læra að nota tölvu og spjaldtölvu', 'active', NOW() - INTERVAL '15 days');

    -- Insert sample goal updates for active goals
    INSERT INTO goal_updates (goal_id, created_by, update_text, progress_type, created_at)
    SELECT 
      g.id,
      sample_user_id,
      CASE 
        WHEN g.title LIKE '%samskipti%' THEN 'Góðar framfarir í samskiptum við starfsfólk'
        WHEN g.title LIKE '%sjálfstæði%' THEN 'Sýnir aukið sjálfstæði í morgunrútínu'
        WHEN g.title LIKE '%félagsleg%' THEN 'Tók þátt í hópverkefni í dag'
        WHEN g.title LIKE '%líkamsrækt%' THEN 'Kláraði alla æfingu vikunnar'
        WHEN g.title LIKE '%læsi%' THEN 'Las heila grein sjálfstætt'
        WHEN g.title LIKE '%tækni%' THEN 'Lærði að nota nýtt forrit'
        ELSE 'Almenn framför í markmiði'
      END,
      'improvement',
      NOW() - INTERVAL '5 days'
    FROM goals g
    WHERE g.status = 'active' AND g.created_by = sample_user_id;

    -- Add some setback examples
    INSERT INTO goal_updates (goal_id, created_by, update_text, progress_type, created_at)
    SELECT 
      g.id,
      sample_user_id,
      'Smá erfiðleikar í dag, en við höldum áfram',
      'setback',
      NOW() - INTERVAL '10 days'
    FROM goals g
    WHERE g.status = 'active' AND g.created_by = sample_user_id
    LIMIT 2;

    -- Add neutral updates
    INSERT INTO goal_updates (goal_id, created_by, update_text, progress_type, created_at)
    SELECT 
      g.id,
      sample_user_id,
      'Venjulegur dagur, engar sérstakar framfarir',
      'neutral',
      NOW() - INTERVAL '15 days'
    FROM goals g
    WHERE g.status = 'active' AND g.created_by = sample_user_id
    LIMIT 3;
  END IF;

  RAISE NOTICE 'Sample data seeding completed successfully';
END $$;