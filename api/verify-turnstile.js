/* eslint-env node */
/* global process */
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  const { token, email, password, fullName, role } = req.body;

  if (!token || !email || !password || !fullName || !role) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  // 1. CAPTCHA Verification
  const formData = new URLSearchParams();
  formData.append('secret', process.env.TURNSTILE_SECRET_KEY);
  formData.append('response', token);

  const verifyRes = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    body: formData
  });

  const verifyJson = await verifyRes.json();
  if (!verifyJson.success) {
    return res.status(403).json({ message: 'CAPTCHA verification failed' });
  }

  // 2. Supabase sign-up via service key
  const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
  if (!SUPABASE_URL) {
    console.error('Missing SUPABASE_URL environment variable');
    return res.status(500).json({ message: 'Server misconfiguration' });
  }

  const signupRes = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email,
      password,
      data: { full_name: fullName, role }
    })
  });

  const signupJson = await signupRes.json();

  if (signupJson.error) {
    return res.status(400).json({ message: signupJson.error.message });
  }

  // 3. Update user profile with provided full name and role
  try {
    const userId = signupJson.user?.id;
    if (userId) {
      await fetch(`${SUPABASE_URL}/rest/v1/user_profiles?id=eq.${userId}`, {
        method: 'PATCH',
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          'Content-Type': 'application/json',
          Prefer: 'return=representation'
        },
        body: JSON.stringify({ full_name: fullName, role })
      });
    }
  } catch (err) {
    console.error('Failed to update user profile:', err);
  }

  return res.status(200).json({ message: 'Signup successful', user: signupJson.user });
}
