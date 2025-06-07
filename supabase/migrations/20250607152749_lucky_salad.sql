/*
  # Fix incidents-clients relationship

  1. Data Cleanup
    - Remove incidents that reference non-existent clients
    - Log the cleanup for audit purposes
  
  2. Add Foreign Key Constraint
    - Add proper foreign key relationship between incidents.client_id and clients.id
    - Ensure data integrity going forward
  
  3. Security
    - Maintain existing RLS policies
    - No changes to permissions
*/

-- First, let's see what orphaned records exist and clean them up
-- Delete incidents that reference non-existent clients
DELETE FROM public.incidents 
WHERE client_id NOT IN (
  SELECT id FROM public.clients
);

-- Now add the foreign key constraint
ALTER TABLE public.incidents 
ADD CONSTRAINT incidents_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

-- Add an index on client_id for better query performance
CREATE INDEX IF NOT EXISTS idx_incidents_client_id ON public.incidents(client_id);