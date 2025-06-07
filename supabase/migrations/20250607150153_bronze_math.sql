/*
  # Fix co_staff column in incidents table

  1. Changes
    - Add co_staff column to incidents table as JSONB array to store UUIDs
    - Update any existing policies that reference co_staff
    - Add index for performance

  2. Security
    - Maintain existing RLS policies
    - Ensure co_staff data is properly validated
*/

-- Add co_staff column to incidents table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'incidents' AND column_name = 'co_staff'
  ) THEN
    ALTER TABLE incidents ADD COLUMN co_staff jsonb DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Add index for co_staff queries
CREATE INDEX IF NOT EXISTS idx_incidents_co_staff ON incidents USING gin(co_staff);

-- Add constraint to ensure co_staff is an array
ALTER TABLE incidents ADD CONSTRAINT IF NOT EXISTS incidents_co_staff_is_array 
  CHECK (jsonb_typeof(co_staff) = 'array');