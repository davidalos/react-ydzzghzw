/*
  # Create Sample Data for Dashboard

  1. New Tables
    - Ensures clients exist for testing
    - Creates sample incidents and goals
    - Adds goal updates for progress tracking

  2. Security
    - Only creates data if users exist
    - Uses existing user profiles for data ownership
    - Respects existing data (no duplicates)

  3. Changes
    - Adds 6 sample clients (Íbúi 1-6)
    - Creates 15 sample incidents across different categories
    - Adds 6 sample goals with various statuses
    - Includes goal updates showing progress types
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
    -- Insert each client individually to avoid SQL issues
    INSERT INTO clients (label) 
    SELECT 'Íbúi 1' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 1');
    
    INSERT INTO clients (label) 
    SELECT 'Íbúi 2' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 2');
    
    INSERT INTO clients (label) 
    SELECT 'Íbúi 3' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 3');
    
    INSERT INTO clients (label) 
    SELECT 'Íbúi 4' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 4');
    
    INSERT INTO clients (label) 
    SELECT 'Íbúi 5' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 5');
    
    INSERT INTO clients (label) 
    SELECT 'Íbúi 6' WHERE NOT EXISTS (SELECT 1 FROM clients WHERE label = 'Íbúi 6');
    
    RAISE NOTICE 'Sample clients created successfully';
  ELSE
    RAISE NOTICE 'Clients already exist, skipping client creation';
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
  user_count integer;
BEGIN
  -- Check if we have any users
  SELECT COUNT(*) INTO user_count FROM user_profiles;
  
  -- If no users exist, skip seeding
  IF user_count = 0 THEN
    RAISE NOTICE 'No user profiles found - skipping sample data creation. Data will be created when users sign up.';
    RETURN;
  END IF;

  -- Get the first available user
  SELECT id INTO sample_user_id FROM user_profiles LIMIT 1;
  
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
    
    RAISE NOTICE 'Sample incidents created successfully';
  ELSE
    RAISE NOTICE 'Incidents already exist, skipping incident creation';
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

    RAISE NOTICE 'Sample goals created successfully';

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

    RAISE NOTICE 'Sample goal updates created successfully';
  ELSE
    RAISE NOTICE 'Goals already exist, skipping goal creation';
  END IF;

  RAISE NOTICE 'Sample data seeding completed successfully for user: %', sample_user_id;
END $$;