import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn(
    'Missing Supabase environment variables. Please connect to Supabase using the "Connect to Supabase" button in the top right corner.'
  );
}

export const supabase = createClient(supabaseUrl || '', supabaseKey || '');

// Initialize Supabase connection
async function initSupabase() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    console.log('Supabase initialized:', !!session);
  } catch (error) {
    console.error('Failed to initialize Supabase:', error.message);
  }
}

initSupabase();