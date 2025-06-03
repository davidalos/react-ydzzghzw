import { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import toast from 'react-hot-toast';

export function useAuth() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let mounted = true;

    async function initialize() {
      try {
        setError(null);

        // Get initial session
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;

        if (!mounted) return;

        if (session?.user) {
          setUser(session.user);
          // Fetch user profile
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .single();

          if (profileError) {
            console.error('Profile fetch error:', profileError);
            toast.error('Failed to load user profile');
            // Clear session if profile fetch fails
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            return;
          }

          if (mounted) {
            setProfile(profile);
            setLoading(false);
          }
        } else {
          // No session, clear user and profile
          if (mounted) {
            setUser(null);
            setProfile(null);
            setLoading(false);
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        if (mounted) {
          setError(error.message);
          setUser(null);
          setProfile(null);
          setLoading(false);
          toast.error('Authentication error. Please try logging in again.');
        }
      }
    }

    // Start initialization
    initialize();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!mounted) return;

      try {
        setLoading(true);
        setError(null);

        if (session?.user) {
          setUser(session.user);
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .single();

          if (profileError) {
            console.error('Profile fetch error:', profileError);
            toast.error('Failed to load user profile');
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            return;
          }

          setProfile(profile);
        } else {
          setUser(null);
          setProfile(null);
        }
      } catch (error) {
        console.error('Auth state change error:', error);
        setError(error.message);
        setUser(null);
        setProfile(null);
        toast.error('Authentication error. Please try logging in again.');
      } finally {
        if (mounted) setLoading(false);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  return {
    user,
    profile,
    isManager: profile?.role === 'manager',
    loading,
    error,
  };
}