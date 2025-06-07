/* eslint-env node */
/* global process */
export default async function handler(req, res) {
  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  const { token, email, password, fullName, role } = req.body;

  if (!token || !email || !password || !fullName || !role) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  // 1. CAPTCHA Verification - Enhanced development detection
  const isDevelopment = process.env.NODE_ENV === 'development' || 
                       process.env.VERCEL_ENV === 'development' ||
                       token === 'XXXX.DUMMY.TOKEN.XXXX' ||
                       process.env.TURNSTILE_SECRET_KEY === '1x0000000000000000000000000000000AA' ||
                       !process.env.TURNSTILE_SECRET_KEY ||
                       process.env.TURNSTILE_SECRET_KEY === 'undefined';

  if (!isDevelopment) {
    try {
      const formData = new URLSearchParams();
      formData.append('secret', process.env.TURNSTILE_SECRET_KEY);
      formData.append('response', token);

      const verifyRes = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
        method: 'POST',
        body: formData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        }
      });

      if (!verifyRes.ok) {
        throw new Error(`CAPTCHA service error: ${verifyRes.status}`);
      }

      const verifyJson = await verifyRes.json();
      
      if (!verifyJson.success) {
        console.error('CAPTCHA verification failed:', verifyJson['error-codes']);
        return res.status(403).json({ 
          message: 'CAPTCHA verification failed',
          errors: verifyJson['error-codes']
        });
      }
      
      console.log('✅ CAPTCHA verified successfully');
    } catch (error) {
      console.error('CAPTCHA verification error:', error);
      return res.status(500).json({ message: 'CAPTCHA verification failed' });
    }
  } else {
    console.log('🔧 Development mode: Skipping CAPTCHA verification');
  }

  // 2. Supabase sign-up via service key
  const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
  const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!SUPABASE_URL || !SERVICE_KEY) {
    console.error('Missing Supabase configuration:', { 
      hasUrl: !!SUPABASE_URL, 
      hasKey: !!SERVICE_KEY 
    });
    return res.status(500).json({ message: 'Server configuration error' });
  }

  try {
    // Create user account
    const signupRes = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
      method: 'POST',
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
        password,
        data: { 
          full_name: fullName.trim(), 
          role: role.toLowerCase() 
        }
      })
    });

    const signupJson = await signupRes.json();

    if (signupJson.error) {
      console.error('Supabase signup error:', signupJson.error);
      return res.status(400).json({ message: signupJson.error.message });
    }

    if (!signupJson.user) {
      console.error('No user returned from signup');
      return res.status(400).json({ message: 'Account creation failed' });
    }

    // 3. Update user profile with provided information
    const userId = signupJson.user.id;
    
    try {
      const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/user_profiles`, {
        method: 'POST',
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({ 
          id: userId,
          full_name: fullName.trim(), 
          role: role.toLowerCase() 
        })
      });

      if (!profileRes.ok) {
        console.error('Profile creation failed:', await profileRes.text());
        // Don't fail the whole signup if profile creation fails
      } else {
        console.log('✅ User profile created successfully');
      }
    } catch (profileError) {
      console.error('Profile creation error:', profileError);
      // Continue anyway - the user account was created
    }

    console.log('✅ User signup completed successfully');
    return res.status(200).json({ 
      message: 'Signup successful', 
      user: { 
        id: signupJson.user.id, 
        email: signupJson.user.email 
      } 
    });

  } catch (error) {
    console.error('Signup process error:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
}