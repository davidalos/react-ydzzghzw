import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../supabase';
import toast from 'react-hot-toast';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // TEMPORARY BYPASS: Create mock user and profile
  const TEMP_BYPASS = true;
  
  useEffect(() => {
    let mounted = true;

    async function fetchSession() {
      try {
        setError(null);
        
        // TEMPORARY BYPASS: Use mock data
        if (TEMP_BYPASS) {
          console.log('🚨 TEMPORARY AUTH BYPASS ACTIVE - Using mock user data');
          if (mounted) {
            setUser({ 
              id: 'temp-user-id', 
              email: 'temp@example.com',
              user_metadata: { full_name: 'Temporary User' }
            });
            setProfile({ 
              id: 'temp-user-id',
              full_name: 'Temporary User', 
              role: 'manager' // Give manager access for testing
            });
            setLoading(false);
          }
          return;
        }

        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        if (!mounted) return;

        if (session?.user) {
          setUser(session.user);
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .limit(1)
            .single();
          if (profileError) {
            console.error('Profile fetch error:', profileError);
            await supabase.auth.signOut();
            if (mounted) {
              setUser(null);
              setProfile(null);
              toast.error('Error loading user profile. Please sign in again.');
            }
            return;
          }
          if (mounted) setProfile(profile);
        }
      } catch (err) {
        console.error('Auth initialization error:', err);
        if (mounted) {
          setError(err.message);
          setUser(null);
          setProfile(null);
        }
      } finally {
        if (mounted) setLoading(false);
      }
    }

    fetchSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!mounted) return;
      
      // Skip auth state changes during bypass
      if (TEMP_BYPASS) return;
      
      try {
        setLoading(true);
        setError(null);
        if (session?.user) {
          setUser(session.user);
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .limit(1)
            .single();
          if (profileError) {
            console.error('Profile fetch error:', profileError);
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            toast.error('Error loading user profile. Please sign in again.');
            return;
          }
          setProfile(profile);
        } else {
          setUser(null);
          setProfile(null);
        }
      } catch (err) {
        console.error('Auth state change error:', err);
        setError(err.message);
        setUser(null);
        setProfile(null);
      } finally {
        if (mounted) setLoading(false);
      }
    });

    function handleVisibility() {
      if (document.visibilityState === 'visible' && !TEMP_BYPASS) {
        fetchSession();
      }
    }
    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      mounted = false;
      subscription.unsubscribe();
      document.removeEventListener('visibilitychange', handleVisibility);
    };
  }, []);

  const value = { user, profile, isManager: profile?.role === 'manager', loading, error };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return ctx;
}