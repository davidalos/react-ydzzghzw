/* eslint-env node, jest */
/* global process, global */
import { describe, it, expect, vi, afterEach } from 'vitest';
import handler from './verify-turnstyle.js';

// Simple helper to create mock response object
function createRes() {
  return {
    status: vi.fn().mockReturnThis(),
    json: vi.fn()
  };
}

describe('verify-turnstyle API', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns 405 for GET requests', async () => {
    const req = { method: 'GET' };
    const res = createRes();

    await handler(req, res);

    expect(res.status).toHaveBeenCalledWith(405);
    expect(res.json).toHaveBeenCalledWith({ message: 'Method Not Allowed' });
  });

  it('returns 200 on successful POST', async () => {
    const req = {
      method: 'POST',
      body: {
        token: 'token',
        email: 'test@example.com',
        password: 'pw',
        fullName: 'Test User',
        role: 'user'
      }
    };
    const res = createRes();

    global.fetch = vi.fn()
      .mockResolvedValueOnce({
        json: vi.fn().mockResolvedValue({ success: true })
      })
      .mockResolvedValueOnce({
        json: vi.fn().mockResolvedValue({})
      });

    process.env.TURNSTILE_SECRET_KEY = 'secret';
    process.env.SUPABASE_URL = 'https://example.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'service_key';

    await handler(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ message: 'Signup successful' });
  });
});
