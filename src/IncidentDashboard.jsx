import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

export default function IncidentDashboard() {
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);

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
      setIncidents(data);
    } catch (error) {
      toast.error('Failed to load incidents');
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="text-center py-4">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold mb-6">Recent Incidents</h2>
      <div className="space-y-4">
        {incidents.map((incident) => (
          <div
            key={incident.id}
            className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex justify-between items-start">
              <div>
                <span
                  className={`inline-block px-2 py-1 text-sm rounded-full ${
                    incident.category === 'Emergency'
                      ? 'bg-red-100 text-red-800'
                      : incident.category === 'Safety'
                      ? 'bg-yellow-100 text-yellow-800'
                      : incident.category === 'Medical'
                      ? 'bg-blue-100 text-blue-800'
                      : incident.category === 'Behavioral'
                      ? 'bg-purple-100 text-purple-800'
                      : 'bg-green-100 text-green-800'
                  }`}
                >
                  {incident.category}
                </span>
                <p className="mt-2 text-sm text-gray-500">
                  Client: {incident.clients?.label}
                </p>
              </div>
              <p className="text-sm text-gray-500">
                {format(new Date(incident.created_at), 'PPp')}
              </p>
            </div>
            <p className="mt-2">{incident.description}</p>
            {incident.reflection && (
              <p className="mt-2 text-gray-600 italic">{incident.reflection}</p>
            )}
            <div className="mt-2 text-sm text-gray-500">
              Reported by: {incident.user_profiles?.full_name}
              {incident.co_staff?.length > 0 && (
                <span>
                  {' '}
                  | Co-staff: {incident.co_staff.join(', ')}
                </span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}