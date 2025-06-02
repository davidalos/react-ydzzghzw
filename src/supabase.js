// src/supabase.js
import { createClient } from '@supabase/supabase-js';

// TEMP hardcoded for StackBlitz
const supabaseUrl = 'https://kybhregztorltmcltjra.supabase.co';
const supabaseKey =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5YmhyZWd6dG9ybHRtY2x0anJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NzU0ODgsImV4cCI6MjA2NDQ1MTQ4OH0.7ws71LmUKGJiFRmyepo2eTlQJ1Of7x8vZbksxvrUNoU';

export const supabase = createClient(supabaseUrl, supabaseKey);
