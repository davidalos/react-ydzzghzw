export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  const { token, email, password } = req.body;

  if (!token || !email || !password) {
    return res.status(400).json({ message: 'Missing fields' });
  }

  // VERIFY CAPTCHA with Cloudflare Turnstile
  const formData = new URLSearchParams();
  formData.append('secret', process.env.TURNSTILE_SECRET_KEY);
  formData.append('response', token);

  const result = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    body: formData
  });

  const json = await result.json();

  if (!json.success) {
    return res.status(403).json({ message: 'Invalid CAPTCHA' });
  }

  // SIGN UP with Supabase (requires service role key!)
  const signupRes = await fetch(`${process.env.SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      'apikey': process.env.SUPABASE_SERVICE_ROLE_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password })
  });

  const signupJson = await signupRes.json();

  if (signupJson.error) {
    return res.status(400).json({ message: signupJson.error.message });
  }

  return res.status(200).json({ message: 'Signup successful!' });
}
//Awesome
