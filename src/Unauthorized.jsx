import React from 'react'

export default function Unauthorized() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900">Unauthorized Access</h1>
        <p className="mt-4 text-gray-600">You don't have permission to access this page.</p>
      </div>
    </div>
  );
}