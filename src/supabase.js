import { createClient } from '@supabase/supabase-js';

// Get environment-specific variables
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    'Missing Supabase environment variables. Please connect to Supabase by clicking the "Connect to Supabase" button in the top right corner.'
  );
}

// Create Supabase client with environment-specific configuration
export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,
    detectSessionInUrl: false,
    autoRefreshToken: true,
    multiTab: true,
    storageKey: `sb.${import.meta.env.MODE}.auth.token`, // Environment-specific storage key
    storage: window.localStorage
  },
  realtime: {
    params: {
      eventsPerSecond: 2
    }
  }
});

// Log environment and connection status
console.log(`Running in ${import.meta.env.MODE} mode`);

// Initialize Supabase connection
async function initSupabase() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    console.log(`Session initialized in ${import.meta.env.MODE} environment:`, session?.user?.id);
    
    const { error } = await supabase
      .from('user_profiles')
      .select('count', { count: 'exact', head: true });
      
    if (error) throw error;
    console.log(`Successfully connected to Supabase (${import.meta.env.MODE})`);
  } catch (error) {
    console.error(`Failed to connect to Supabase (${import.meta.env.MODE}):`, error.message);
  }
}

initSupabase();