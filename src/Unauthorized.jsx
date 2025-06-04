import React from 'react';

export default function Unauthorized() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded shadow text-center">
        <h1 className="text-2xl font-bold mb-4">Aðgangi hafnað</h1>
        <p className="text-gray-600">Þú hefur ekki réttindi til að skoða þessa síðu.</p>
      </div>
    </div>
  );
}
