import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    'Missing Supabase environment variables. Please connect to Supabase by clicking the "Connect to Supabase" button in the top right corner.'
  );
}

// Create Supabase client with additional options for better error handling
export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,
    detectSessionInUrl: false,
    autoRefreshToken: true,
    multiTab: true,
    storageKey: 'supabase.auth.token',
    storage: window.localStorage
  },
  realtime: {
    params: {
      eventsPerSecond: 2
    }
  }
});

// Test connection and log status
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth state changed:', event, session?.user?.id);
});

// Initialize Supabase connection
async function initSupabase() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    console.log('Session initialized:', session?.user?.id);
    
    const { error } = await supabase
      .from('user_profiles')
      .select('count', { count: 'exact', head: true });
      
    if (error) throw error;
    console.log('Successfully connected to Supabase');
  } catch (error) {
    console.error('Failed to connect to Supabase:', error.message);
  }
}

initSupabase();