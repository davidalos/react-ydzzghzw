// src/hooks/useRole.js

import { useState, useEffect } from 'react';

export function useRole() {
  const [role, setRole] = useState('staff'); // default to 'staff'

  useEffect(() => {
    const stored = localStorage.getItem('userRole');
    if (stored === 'manager' || stored === 'staff') {
      setRole(stored);
    }
  }, []);

  const switchRole = () => {
    const newRole = role === 'manager' ? 'staff' : 'manager';
    setRole(newRole);
    localStorage.setItem('userRole', newRole);
  };

  return { role, switchRole, isManager: role === 'manager' };
}
