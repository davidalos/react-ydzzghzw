import { useEffect, useState } from 'react';
import { supabase } from '../supabase';

export function useAuth() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let mounted = true;

    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!mounted) return;
      
      setUser(session?.user ?? null);
      if (session?.user) {
        loadUserProfile(session.user.id);
      } else {
        setLoading(false);
      }
    }).catch(err => {
      if (!mounted) return;
      console.error('Error getting session:', err.message);
      setError(err.message);
      setLoading(false);
    });

    // Listen for changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!mounted) return;
      
      setUser(session?.user ?? null);
      if (session?.user) {
        await loadUserProfile(session.user.id);
      } else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  async function loadUserProfile(userId) {
    try {
      setError(null);
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        throw error;
      }

      if (!data) {
        throw new Error('No profile found');
      }

      setProfile(data);
    } catch (error) {
      console.error('Error loading user profile:', error.message);
      setError(error.message);
      setProfile(null);
    } finally {
      setLoading(false);
    }
  }

  const isManager = profile?.role === 'manager';
  
  return {
    user,
    profile,
    isManager,
    loading,
    error,
  };
}