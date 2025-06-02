// src/Login.js
import React, { useState } from 'react';
import { supabase } from './supabase';

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('');

  async function handleLogin(e) {
    e.preventDefault();
    const { error } = await supabase.auth.signInWithOtp({ email });
    if (error) alert('Login error: ' + error.message);
    else alert('Check your email for the login link!');
  }

  return (
    <form onSubmit={handleLogin}>
      <h2>Log In</h2>
      <input
        type="email"
        placeholder="Your email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <button type="submit">Send Magic Link</button>
    </form>
  );
}
