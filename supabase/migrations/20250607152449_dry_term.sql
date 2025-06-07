/*
  # Add foreign key constraint for incidents-clients relationship

  1. Changes
    - Add foreign key constraint linking incidents.client_id to clients.id
    - This enables Supabase to understand the relationship for joins

  2. Security
    - No RLS changes needed as both tables already have appropriate policies
*/

-- Add the missing foreign key constraint between incidents and clients
ALTER TABLE public.incidents 
ADD CONSTRAINT incidents_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id);