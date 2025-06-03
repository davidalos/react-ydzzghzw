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
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError) throw sessionError;
        if (!mounted) return;

        if (session?.user) {
          setUser(session.user);
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', session.user.id)
            .maybeSingle();

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

          if (!profile) {
            console.error('No profile found for user:', session.user.id);
            await supabase.auth.signOut();
            if (mounted) {
              setUser(null);
              setProfile(null);
              toast.error('User profile not found. Please sign up again.');
            }
            return;
          }

          if (mounted) {
            setProfile(profile);
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        if (mounted) {
          setError(error.message);
          setUser(null);
          setProfile(null);
        }
      } finally {
        if (mounted) setLoading(false);
      }
    }

    initialize();

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
            .maybeSingle();

          if (profileError) {
            console.error('Profile fetch error:', profileError);
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            toast.error('Error loading user profile. Please sign in again.');
            return;
          }

          if (!profile) {
            console.error('No profile found for user:', session.user.id);
            await supabase.auth.signOut();
            setUser(null);
            setProfile(null);
            toast.error('User profile not found. Please sign up again.');
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