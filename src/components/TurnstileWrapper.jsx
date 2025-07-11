import React, { useState, useEffect } from 'react';
import Turnstile from 'react-turnstile';

export function TurnstileWrapper({ onVerify, onError, onExpire }) {
  const [isProduction, setIsProduction] = useState(false);
  const [siteKey, setSiteKey] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Detect environment and set appropriate site key
    const hostname = window.location.hostname;
    const isDev = hostname === 'localhost' || 
                  hostname.includes('bolt.new') || 
                  hostname.includes('stackblitz') ||
                  hostname.includes('webcontainer') ||
                  process.env.NODE_ENV === 'development' ||
                  import.meta.env.DEV;
    
    if (isDev) {
      // Use Cloudflare's test site key for development
      setSiteKey('1x00000000000000000000AA');
      setIsProduction(false);
      console.log('🔧 Development mode: Using test CAPTCHA');
    } else {
      // Use production site key
      const prodKey = import.meta.env.VITE_TURNSTILE_SITE_KEY;
      if (prodKey && prodKey !== 'undefined') {
        setSiteKey(prodKey);
        setIsProduction(true);
        console.log('🚀 Production mode: Using real CAPTCHA');
      } else {
        // Fallback to test key if production key is missing
        setSiteKey('1x00000000000000000000AA');
        setIsProduction(false);
        console.warn('⚠️ Missing production CAPTCHA key, using test key');
      }
    }
    setIsLoading(false);
  }, []);

  const handleVerify = (token) => {
    // Always pass the actual token from Turnstile, whether it's test or production
    console.log(isProduction ? '✅ CAPTCHA verified successfully' : '🔧 Test CAPTCHA token received');
    onVerify(token);
  };

  const handleError = (error) => {
    console.error('❌ CAPTCHA error:', error);
    // Let the parent component handle the error properly
    onError && onError();
  };

  const handleExpire = () => {
    console.log('⏰ CAPTCHA expired');
    // Let the parent component handle the expiration properly
    onExpire && onExpire();
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-4 bg-gray-100 rounded">
        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-600 mr-2"></div>
        <span className="text-sm text-gray-600">Loading CAPTCHA...</span>
      </div>
    );
  }

  if (!siteKey) {
    return (
      <div className="flex items-center justify-center p-4 bg-red-100 rounded">
        <span className="text-sm text-red-600">CAPTCHA configuration error</span>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center space-y-2">
      <Turnstile
        sitekey={siteKey}
        onVerify={handleVerify}
        onError={handleError}
        onExpire={handleExpire}
        theme="light"
        size="normal"
        retry="auto"
      />
      {!isProduction && (
        <div className="text-xs text-gray-500 bg-yellow-50 px-2 py-1 rounded">
          Development Mode - Using Test Token
        </div>
      )}
    </div>
  );
}