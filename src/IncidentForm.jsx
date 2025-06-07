import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';
import { useAuth } from './hooks/useAuth';
import toast from 'react-hot-toast';

export default function IncidentForm() {
  const { user, profile } = useAuth();
  const [clients, setClients] = useState([]);
  const [formData, setFormData] = useState({
    clientId: '',
    category: '',
    description: '',
    reflection: '',
    serious: false,
    coStaff: '',
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadClients();
  }, []);

  async function loadClients() {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('label', { ascending: true });
    
    if (error) {
      toast.error('Error loading clients');
      console.error('Error:', error);
    } else {
      setClients(data);
    }
  }

  const categories = [
    'Positive Progress',
    'Medical',
    'Behavioral',
    'Safety',
    'Emergency',
  ];

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);

    try {
      if (!formData.clientId || !formData.category || !formData.description) {
        throw new Error('Please fill in all required fields');
      }

      // Convert co_staff string to array of UUIDs (if provided)
      const coStaffArray = formData.coStaff
        ? formData.coStaff
            .split(',')
            .map(s => s.trim())
            .filter(Boolean)
        : [];

      const { error } = await supabase.from('incidents').insert({
        client_id: formData.clientId,
        category: formData.category,
        description: formData.description,
        reflection: formData.reflection,
        serious: formData.serious,
        submitted_by: user.id,
        co_staff: coStaffArray, // Store as JSONB array
      });

      if (error) throw error;

      toast.success('Incident recorded successfully');

      // Save a local copy for offline access
      const offline = JSON.parse(localStorage.getItem('offlineIncidents') || '[]');
      offline.unshift({
        id: Date.now(),
        created_at: new Date().toISOString(),
        client_id: formData.clientId,
        category: formData.category,
        description: formData.description,
        reflection: formData.reflection,
        serious: formData.serious,
        submitted_by: user.id,
        co_staff: coStaffArray,
        user_profiles: { full_name: profile?.full_name || '' }
      });
      localStorage.setItem('offlineIncidents', JSON.stringify(offline));

      // Reset form
      setFormData({
        clientId: '',
        category: '',
        description: '',
        reflection: '',
        serious: false,
        coStaff: '',
      });

    } catch (error) {
      toast.error(error.message);
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-2xl mx-auto bg-white p-6 rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-6">Skrá atvik</h2>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Íbúi *
          </label>
          <select
            name="clientId"
            value={formData.clientId}
            onChange={handleInputChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            required
          >
            <option value="">Veldu íbúa</option>
            {clients.map((client) => (
              <option key={client.id} value={client.id}>
                {client.label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Flokkur *
          </label>
          <select
            name="category"
            value={formData.category}
            onChange={handleInputChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            required
          >
            <option value="">Veldu flokk</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Lýsing *
          </label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            rows="4"
            required
            placeholder="Hvað gerðist?"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Hugleiðing
          </label>
          <textarea
            name="reflection"
            value={formData.reflection}
            onChange={handleInputChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            rows="3"
            placeholder="Hvað hefði mátt fara öðruvísi? Hvernig brást teymið við?"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Samstarfsmenn (UUID)
          </label>
          <input
            type="text"
            name="coStaff"
            value={formData.coStaff}
            onChange={handleInputChange}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            placeholder="UUID aðskilin með kommu"
          />
          <p className="mt-1 text-sm text-gray-500">
            Enter valid UUIDs separated by commas (optional)
          </p>
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            name="serious"
            checked={formData.serious}
            onChange={handleInputChange}
            className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
          />
          <label className="ml-2 block text-sm text-gray-900">
            Alvarlegt atvik
          </label>
        </div>

        <div>
          <button
            type="submit"
            disabled={loading}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {loading ? 'Skrái...' : 'Skrá atvik'}
          </button>
        </div>
      </form>
    </div>
  );
}