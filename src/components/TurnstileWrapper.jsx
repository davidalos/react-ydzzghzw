import React, { useState, useEffect } from 'react';
import Turnstile from 'react-turnstile';

export function TurnstileWrapper({ onVerify, onError, onExpire }) {
  const [isProduction, setIsProduction] = useState(false);
  const [siteKey, setSiteKey] = useState('');

  useEffect(() => {
    // Detect environment and set appropriate site key
    const hostname = window.location.hostname;
    const isDev = hostname === 'localhost' || hostname.includes('bolt.new') || hostname.includes('stackblitz');
    
    if (isDev) {
      // Use Cloudflare's test site key for development
      setSiteKey('1x00000000000000000000AA');
      setIsProduction(false);
    } else {
      // Use production site key
      setSiteKey(import.meta.env.VITE_TURNSTILE_SITE_KEY);
      setIsProduction(true);
    }
  }, []);

  const handleVerify = (token) => {
    if (!isProduction) {
      // In development, always return a dummy token
      onVerify('XXXX.DUMMY.TOKEN.XXXX');
    } else {
      onVerify(token);
    }
  };

  const handleError = () => {
    if (!isProduction) {
      // In development, simulate successful verification
      onVerify('XXXX.DUMMY.TOKEN.XXXX');
    } else {
      onError && onError();
    }
  };

  if (!siteKey) {
    return (
      <div className="flex items-center justify-center p-4 bg-gray-100 rounded">
        <span className="text-sm text-gray-600">Loading CAPTCHA...</span>
      </div>
    );
  }

  return (
    <div className="flex justify-center">
      <Turnstile
        sitekey={siteKey}
        onVerify={handleVerify}
        onError={handleError}
        onExpire={onExpire}
        theme="light"
        size="normal"
      />
      {!isProduction && (
        <div className="ml-2 text-xs text-gray-500 self-center">
          (Dev mode)
        </div>
      )}
    </div>
  );
}