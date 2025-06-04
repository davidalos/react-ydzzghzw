import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
import { format } from 'date-fns';

export default function IncidentDashboard() {
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errorState, setErrorState] = useState(false);

  useEffect(() => {
    loadIncidents();
  }, []);

  async function loadIncidents() {
    try {
      const { data, error } = await supabase
        .from('incidents')
        .select(`
          *,
          clients(label),
          user_profiles!incidents_submitted_by_fkey(full_name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setIncidents(data || []);
      localStorage.setItem('offlineIncidents', JSON.stringify(data || []));
      setErrorState(false);
    } catch (error) {
      console.error('🧨 Incident Load Error:', error.message || error);
      const offline = JSON.parse(localStorage.getItem('offlineIncidents') || '[]');
      if (offline.length) {
        setIncidents(offline);
        setErrorState(false);
      } else {
        setErrorState(true);
      }
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="text-center py-6">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 mx-auto border-gray-900" />
        <p className="mt-2 text-gray-600 text-sm">Loading incidents…</p>
      </div>
    );
  }

  if (errorState) {
    return (
      <div className="text-center text-red-600 py-6">
        <p>⚠️ Could not load incidents. Try again later.</p>
      </div>
    );
  }

  if (incidents.length === 0) {
    return (
      <div className="text-center py-6 text-gray-500">
        <p>No incidents recorded yet.</p>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-3xl mx-auto">
      <h2 className="text-xl font-semibold mb-4">All Incidents</h2>
      <ul className="space-y-4">
        {incidents.map((incident) => (
          <li key={incident.id} className="p-4 border rounded-xl shadow-sm bg-white">
            <p className="text-sm text-gray-600 mb-1">
              {format(new Date(incident.created_at), 'PPpp')}
            </p>
            <p className="text-md font-medium mb-1">{incident.clients?.label}</p>
            <p className="text-gray-800 whitespace-pre-wrap">{incident.description}</p>
            <p className="text-xs text-gray-400 mt-2">
              Submitted by: {incident.user_profiles?.full_name || 'Unknown'}
            </p>
          </li>
        ))}
      </ul>
    </div>
  );
}
