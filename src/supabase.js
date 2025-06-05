// src/supabase.js
import { createClient } from '@supabase/supabase-js';

// Read credentials from environment variables
// Support both Vite (`VITE_*`) and Next.js (`NEXT_PUBLIC_*`) prefixes so the
// same build can run in different environments without changes.
const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

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
