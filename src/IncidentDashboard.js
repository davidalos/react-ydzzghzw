// src/IncidentDashboard.js
import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';

export default function IncidentDashboard() {
  const [incidents, setIncidents] = useState([]);

  useEffect(() => {
    async function load() {
      const { data, error } = await supabase
        .from('incidents')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) console.error('Error:', error.message);
      else setIncidents(data);
    }
    load();
  }, []);

  return (
    <div>
      <h2>Incident Dashboard</h2>
      {incidents.map((inc) => (
        <div key={inc.id} style={{ marginBottom: '1em' }}>
          <strong>{inc.category}</strong> — {inc.created_at}
          <p>{inc.description}</p>
        </div>
      ))}
    </div>
  );
}
