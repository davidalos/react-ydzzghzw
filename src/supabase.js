// src/supabase.js
import { createClient } from '@supabase/supabase-js';

// Hardcoded here for Codespaces simplicity (but .env is still preferred)
const supabaseUrl = 'https://kybhregztorltmcltjra.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5YmhyZWd6dG9ybHRtY2x0anJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NzU0ODgsImV4cCI6MjA2NDQ1MTQ4OH0.7ws71LmUKGJiFRmyepo2eTlQJ1Of7x8vZbksxvrUNoU';

// Fallback + error warning for environments like Vercel or Netlify
if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
    '[⚠️ Supabase] Missing credentials — check your .env file or hardcoded keys.'
  );
}

// Initialize client with safe config
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    detectSessionInUrl: true,
    autoRefreshToken: true,
    multiTab: true,
    storage: globalThis?.localStorage ?? window.localStorage,
    storageKey: 'supabase.auth.token'
  }
});

// 🔄 Optional: Initialize a session check on app load
export async function checkSupabaseSession() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    console.log('[✅ Supabase] Connected — session active:', !!session);
  } catch (err) {
    console.error('[❌ Supabase] Failed to connect:', err.message);
  }
}

// Auto-run check
checkSupabaseSession();
