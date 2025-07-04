// src/supabase.js
import { createClient } from '@supabase/supabase-js';

// Enhanced environment variable detection with fallbacks
const getSupabaseUrl = () => {
  const url = import.meta.env.VITE_SUPABASE_URL || 
             import.meta.env.NEXT_PUBLIC_SUPABASE_URL ||
             'https://kybhregztorltmcltjra.supabase.co';
  
  console.log('🔧 Supabase URL:', url);
  return url;
};

const getSupabaseAnonKey = () => {
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY || 
             import.meta.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
             'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdGpzZWtveWxpeGNyYmZuYWJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk2NTY5NzAsImV4cCI6MjAyNTIzMjk3MH0.0C_kQxJJXSz7svXg4J_0-cj_8yP1ESA_2cGHp5eNQpM';
  
  console.log('🔧 Supabase Anon Key:', key.substring(0, 50) + '...');
  return key;
};

const supabaseUrl = getSupabaseUrl();
const supabaseAnonKey = getSupabaseAnonKey();

// Validate credentials before creating client
if (!supabaseUrl || !supabaseAnonKey) {
  console.error('[❌ Supabase] Missing credentials:', { 
    hasUrl: !!supabaseUrl, 
    hasKey: !!supabaseAnonKey 
  });
  throw new Error('Missing Supabase credentials. Please check your environment variables.');
}

// Initialize client with enhanced configuration
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    detectSessionInUrl: true,
    autoRefreshToken: true,
    multiTab: true,
    storage: globalThis?.localStorage ?? window.localStorage,
    storageKey: 'supabase.auth.token',
    // Enhanced session configuration
    flowType: 'pkce',
    debug: process.env.NODE_ENV === 'development'
  },
  // Enhanced global configuration
  global: {
    headers: {
      'X-Client-Info': 'atvikaskraning-kopavogur@1.0.0'
    }
  },
  // Database configuration
  db: {
    schema: 'public'
  },
  // Realtime configuration
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});

// Enhanced session check with better error handling
export async function checkSupabaseSession() {
  try {
    console.log('🔄 Checking Supabase connection...');
    
    // Test the connection with a simple query
    const { data, error } = await supabase
      .from('clients')
      .select('count')
      .limit(1);
    
    if (error) {
      console.error('[❌ Supabase] Connection test failed:', error.message);
      throw error;
    }
    
    // Check current session
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('[❌ Supabase] Session check failed:', sessionError.message);
      throw sessionError;
    }
    
    console.log('[✅ Supabase] Connected successfully');
    console.log('[✅ Supabase] Session active:', !!session);
    
    return { connected: true, session: !!session };
    
  } catch (err) {
    console.error('[❌ Supabase] Failed to connect:', err.message);
    return { connected: false, error: err.message };
  }
}

// Auto-run connection check
checkSupabaseSession();

// Export connection status for debugging
export const getConnectionStatus = () => ({
  url: supabaseUrl,
  hasKey: !!supabaseAnonKey,
  keyPreview: supabaseAnonKey ? supabaseAnonKey.substring(0, 20) + '...' : 'missing'
});