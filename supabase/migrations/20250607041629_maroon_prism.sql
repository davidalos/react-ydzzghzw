/*
  # Make clients.label column nullable

  1. Changes
    - Alter clients table to allow NULL values in label column
    - This is a safe structural change that doesn't affect existing data
    
  2. Security
    - No RLS policy changes needed
    - Existing data remains intact
    - Application logic can handle nullable labels
*/

-- Make 'label' column nullable in 'clients' table
-- KEYBRIDGE Protocol: Safe structural update, no destructive data loss
ALTER TABLE clients 
  ALTER COLUMN label DROP NOT NULL;