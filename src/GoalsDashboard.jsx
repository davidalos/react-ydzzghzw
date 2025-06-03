// GoalsDashboard.jsx

import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
import toast from 'react-hot-toast';
import { useAuth } from './hooks/useAuth';
import VoiceTextInput from './components/VoiceTextInput';

export default function GoalsDashboard() {
  const [clients, setClients] = useState([]);
  const [goals, setGoals] = useState([]);
  const [newGoal, setNewGoal] = useState({
    client_id: '',
    title: '',
    description: '',
  });
  const [loading, setLoading] = useState(false);
  const [errorState, setErrorState] = useState(false);
  const [goalLoading, setGoalLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    loadClients();
    loadGoals();
  }, []);

  async function loadClients() {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('label', { ascending: true });

    if (error) {
      console.error('🧨 Clients Load Error:', error.message || error);
      setErrorState(true);
    } else {
      setClients(data || []);
      setErrorState(false);
    }
  }

  async function loadGoals() {
    setGoalLoading(true);
    try {
      const { data, error } = await supabase
        .from('goals')
        .select('*, clients(label)')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setGoals(data || []);
      setErrorState(false);
    } catch (error) {
      console.error('🧨 Goals Load Error:', error.message || error);
      setErrorState(true);
    } finally {
      setGoalLoading(false);
    }
  }

  async function handleCreateGoal(e) {
    e.preventDefault();
    setLoading(true);

    try {
      if (!newGoal.client_id.trim() || !newGoal.title.trim()) {
        throw new Error('Please fill in all required fields');
      }

      const { error } = await supabase.from('goals').insert({
        client_id: newGoal.client_id,
        title: newGoal.title.trim(),
        description: newGoal.description.trim(),
        created_by: user.id,
      });

      if (error) throw error;

      toast.success('Goal created successfully');
      setNewGoal({ client_id: '', title: '', description: '' });
      loadGoals();
    } catch (error) {
      toast.error(error.message);
      console.error('Create Goal Error:', error);
    } finally {
      setLoading(false);
    }
  }

  async function changeGoalStatus(goalId, newStatus) {
    setLoading(true);
    try {
      const { error } = await supabase
        .from('goals')
        .update({ status: newStatus })
        .eq('id', goalId);

      if (error) throw error;

      toast.success('Goal status updated');
      loadGoals();
    } catch (error) {
      toast.error('Failed to update goal status');
      console.error('Update Goal Error:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-8">
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold mb-6">Create New Goal</h2>
        <form onSubmit={handleCreateGoal} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Client *
            </label>
            <select
              value={newGoal.client_id}
              onChange={(e) =>
                setNewGoal({ ...newGoal, client_id: e.target.value })
              }
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            >
              <option value="">Select client</option>
              {clients.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Title *
            </label>
            <input
              type="text"
              placeholder="Goal title"
              value={newGoal.title}
              onChange={(e) => setNewGoal({ ...newGoal, title: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <VoiceTextInput
              value={newGoal.description}
              onChange={(e) =>
                setNewGoal({ ...newGoal, description: e.target.value })
              }
              placeholder="Goal description"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            {loading ? 'Creating...' : 'Create Goal'}
          </button>
        </form>
      </div>

      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold mb-6">Active Goals</h2>

        {goalLoading ? (
          <div className="text-center text-gray-500 py-4">Loading goals…</div>
        ) : errorState ? (
          <div className="text-center text-red-600 py-4">
            ⚠️ Could not load goals. Try again later.
          </div>
        ) : goals.length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            No goals have been created yet.
          </div>
        ) : (
          <div className="space-y-4">
            {goals.map((goal) => (
              <div
                key={goal.id}
                className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
              >
                <div className="flex justify-between items-start flex-wrap gap-2">
                  <div>
                    <h3 className="text-lg font-semibold">{goal.title}</h3>
                    <p className="text-sm text-gray-500">
                      Client: {goal.clients?.label}
                    </p>
                  </div>
                  <span
                    className={`px-2 py-1 text-sm rounded-full ${
                      goal.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : goal.status === 'completed'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {goal.status}
                  </span>
                </div>
                {goal.description && (
                  <p className="mt-2 text-gray-600 whitespace-pre-wrap">
                    {goal.description}
                  </p>
                )}
                <div className="mt-4 flex flex-wrap gap-2">
                  <button
                    onClick={() => changeGoalStatus(goal.id, 'completed')}
                    disabled={loading}
                    className="text-sm px-3 py-1 rounded bg-green-50 text-green-700 hover:bg-green-100"
                  >
                    Mark Complete
                  </button>
                  <button
                    onClick={() => changeGoalStatus(goal.id, 'archived')}
                    disabled={loading}
                    className="text-sm px-3 py-1 rounded bg-gray-50 text-gray-700 hover:bg-gray-100"
                  >
                    Archive
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
