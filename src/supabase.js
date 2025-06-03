import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://fsxtvtbykblkppgchyax.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeHR2dGJ5a2Jsa3BwZ2NoeWF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5MDgyOTAsImV4cCI6MjA2NDQ4NDI5MH0.vFOofkXTUqUT7JbWa8XbKzjhl6ji5NFKDKkvs_h28CM';

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    'Missing Supabase environment variables. Please connect to Supabase by clicking the "Connect to Supabase" button in the top right corner.'
  );
}

// Validate URL format
try {
  new URL(supabaseUrl);
} catch (error) {
  throw new Error(
    'Invalid Supabase URL format. Please reconnect to Supabase by clicking the "Connect to Supabase" button in the top right corner.'
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
  db: {
    schema: 'public'
  }
});

// Test the connection using a simple health check
supabase.auth.getSession()
  .then(() => {
    console.log('Successfully connected to Supabase');
  })
  .catch((error) => {
    console.error('Failed to connect to Supabase:', error.message);
  });