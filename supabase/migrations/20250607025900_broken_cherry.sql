/*
  # Seed Sample Data for Dashboard

  1. Sample Data Creation
    - Add sample clients (Íbúar)
    - Add sample incidents across different categories
    - Add sample goals and goal updates
    - Add sample user profiles for testing

  2. Data Variety
    - Multiple incident types and dates
    - Different goal statuses and progress types
    - Realistic timestamps for trend analysis

  3. Dashboard Testing
    - Enough data to populate charts and tables
    - Various scenarios for comprehensive testing
*/

-- Insert sample clients if they don't exist
INSERT INTO clients (label) VALUES 
  ('Íbúi 1'),
  ('Íbúi 2'),
  ('Íbúi 3'),
  ('Íbúi 4'),
  ('Íbúi 5'),
  ('Íbúi 6')
ON CONFLICT (label) DO NOTHING;

-- Get client IDs for reference
DO $$
DECLARE
  client1_id uuid;
  client2_id uuid;
  client3_id uuid;
  client4_id uuid;
  client5_id uuid;
  client6_id uuid;
  sample_user_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Get client IDs
  SELECT id INTO client1_id FROM clients WHERE label = 'Íbúi 1' LIMIT 1;
  SELECT id INTO client2_id FROM clients WHERE label = 'Íbúi 2' LIMIT 1;
  SELECT id INTO client3_id FROM clients WHERE label = 'Íbúi 3' LIMIT 1;
  SELECT id INTO client4_id FROM clients WHERE label = 'Íbúi 4' LIMIT 1;
  SELECT id INTO client5_id FROM clients WHERE label = 'Íbúi 5' LIMIT 1;
  SELECT id INTO client6_id FROM clients WHERE label = 'Íbúi 6' LIMIT 1;

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
    (client3_id, sample_user_id, 'Positive Progress', 'Náði persónulegu markmiði', false, NOW() - INTERVAL '15 days')
  ON CONFLICT DO NOTHING;

  -- Insert sample goals
  INSERT INTO goals (client_id, created_by, title, description, status, created_at) VALUES
    (client1_id, sample_user_id, 'Bæta samskiptahæfni', 'Vinna að því að bæta munnlega samskipti', 'active', NOW() - INTERVAL '30 days'),
    (client2_id, sample_user_id, 'Sjálfstæði í daglegum verkefnum', 'Auka sjálfstæði við persónulega umhirðu', 'active', NOW() - INTERVAL '25 days'),
    (client3_id, sample_user_id, 'Félagsleg þátttaka', 'Taka þátt í fleiri félagslegum athöfnum', 'active', NOW() - INTERVAL '20 days'),
    (client4_id, sample_user_id, 'Líkamsrækt og heilsa', 'Viðhalda reglulegri líkamsrækt', 'completed', NOW() - INTERVAL '45 days'),
    (client5_id, sample_user_id, 'Læsi og skrift', 'Bæta lestrar- og skriftarhæfni', 'active', NOW() - INTERVAL '35 days'),
    (client6_id, sample_user_id, 'Tækninotkun', 'Læra að nota tölvu og spjaldtölvu', 'active', NOW() - INTERVAL '15 days')
  ON CONFLICT DO NOTHING;

  -- Insert sample goal updates
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
    END,
    'improvement',
    NOW() - INTERVAL '5 days'
  FROM goals g
  WHERE g.status = 'active'
  ON CONFLICT DO NOTHING;

  -- Add some setback examples
  INSERT INTO goal_updates (goal_id, created_by, update_text, progress_type, created_at)
  SELECT 
    g.id,
    sample_user_id,
    'Smá erfiðleikar í dag, en við höldum áfram',
    'setback',
    NOW() - INTERVAL '10 days'
  FROM goals g
  WHERE g.status = 'active'
  LIMIT 2
  ON CONFLICT DO NOTHING;

  -- Add neutral updates
  INSERT INTO goal_updates (goal_id, created_by, update_text, progress_type, created_at)
  SELECT 
    g.id,
    sample_user_id,
    'Venjulegur dagur, engar sérstakar framfarir',
    'neutral',
    NOW() - INTERVAL '15 days'
  FROM goals g
  WHERE g.status = 'active'
  LIMIT 3
  ON CONFLICT DO NOTHING;

END $$;