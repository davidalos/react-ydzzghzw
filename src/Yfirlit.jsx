import React from 'react';
import { ManagerDashboard } from './components/ManagerDashboard.jsx';

export default function Yfirlit() {
  // Accessible to all users - no role restrictions
  return (
    <div className="min-h-screen bg-gray-50">
      <ManagerDashboard />
    </div>
  );
}