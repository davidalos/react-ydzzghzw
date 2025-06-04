import React from 'react';
import { Link } from 'react-router-dom';

export default function Unauthorized() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-2xl font-bold mb-4">Unauthorized</h1>
        <p className="mb-4">You do not have access to this page.</p>
        <Link to="/" className="text-indigo-600 hover:text-indigo-800">
          Go back home
        </Link>
      </div>
    </div>
  );
}
