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
    detectSessionInUrl: true,
    autoRefreshToken: true,
    multiTab: true
  },
  global: {
    headers: {
      'X-Client-Info': 'supabase-js-web'
    }
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});

// Test the connection
supabase.auth.getSession().then(({ data: { session } }) => {
  if (session) {
    console.log('Successfully connected to Supabase');
  }
}).catch(error => {
  console.error('Failed to connect to Supabase:', error.message);
});