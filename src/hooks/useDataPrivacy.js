import { useState, useEffect } from 'react';

export function useDataPrivacy() {
  const [hasAcceptedPrivacy, setHasAcceptedPrivacy] = useState(false);
  const [showPrivacyNotice, setShowPrivacyNotice] = useState(false);

  useEffect(() => {
    const accepted = localStorage.getItem('data-privacy-accepted');
    const acceptedDate = localStorage.getItem('data-privacy-date');
    
    // Check if privacy was accepted and if it's still valid (within 1 year)
    if (accepted === 'true' && acceptedDate) {
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
      
      if (new Date(acceptedDate) > oneYearAgo) {
        setHasAcceptedPrivacy(true);
      } else {
        // Privacy acceptance expired, show notice again
        setShowPrivacyNotice(true);
      }
    } else {
      setShowPrivacyNotice(true);
    }
  }, []);

  const acceptPrivacy = () => {
    localStorage.setItem('data-privacy-accepted', 'true');
    localStorage.setItem('data-privacy-date', new Date().toISOString());
    setHasAcceptedPrivacy(true);
    setShowPrivacyNotice(false);
  };

  const declinePrivacy = () => {
    localStorage.removeItem('data-privacy-accepted');
    localStorage.removeItem('data-privacy-date');
    setHasAcceptedPrivacy(false);
    setShowPrivacyNotice(false);
    // Redirect to external page or show alternative content
    window.location.href = 'https://kopavogur.is';
  };

  return {
    hasAcceptedPrivacy,
    showPrivacyNotice,
    acceptPrivacy,
    declinePrivacy
  };
}