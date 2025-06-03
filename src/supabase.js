import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn(
    'Missing Supabase environment variables. Please connect to Supabase using the "Connect to Supabase" button in the top right corner.'
  );
}

// Create Supabase client with environment-specific configuration
export const supabase = createClient(supabaseUrl || '', supabaseKey || '', {
  auth: {
    persistSession: true,
    detectSessionInUrl: true,
    autoRefreshToken: true,
    multiTab: true,
    storageKey: 'supabase.auth.token',
    storage: globalThis?.localStorage
  }
});

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