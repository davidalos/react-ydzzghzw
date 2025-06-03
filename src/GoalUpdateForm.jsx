import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
import { useAuth } from './hooks/useAuth';
import toast from 'react-hot-toast';

export default function GoalUpdateForm() {
  const { user } = useAuth();
  const [goals, setGoals] = useState([]);
  const [selectedGoal, setSelectedGoal] = useState('');
  const [updateText, setUpdateText] = useState('');
  const [progressType, setProgressType] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadActiveGoals();
  }, []);

  async function loadActiveGoals() {
    try {
      const { data, error } = await supabase
        .from('goals')
        .select('*, clients(label)')
        .eq('status', 'active')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setGoals(data);
    } catch (error) {
      toast.error('Failed to load goals');
      console.error('Error:', error);
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);

    try {
      if (!selectedGoal || !updateText || !progressType) {
        throw new Error('Please fill in all required fields');
      }

      const { error } = await supabase.from('goal_updates').insert({
        goal_id: selectedGoal,
        update_text: updateText,
        progress_type: progressType,
        created_by: user.id,
      });

      if (error) throw error;

      toast.success('Update recorded successfully');
      setSelectedGoal('');
      setUpdateText('');
      setProgressType('');
      loadActiveGoals(); // Refresh goals list
    } catch (error) {
      toast.error(error.message);
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold mb-6">Record Goal Progress</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Select Goal *
          </label>
          <select
            value={selectedGoal}
            onChange={(e) => setSelectedGoal(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            required
          >
            <option value="">Choose a goal</option>
            {goals.map((goal) => (
              <option key={goal.id} value={goal.id}>
                {goal.title} ({goal.clients?.label})
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Update Details *
          </label>
          <textarea
            value={updateText}
            onChange={(e) => setUpdateText(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            rows="3"
            placeholder="Describe the progress or setback"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Progress Type *
          </label>
          <select
            value={progressType}
            onChange={(e) => setProgressType(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            required
          >
            <option value="">Select type</option>
            <option value="improvement">Improvement</option>
            <option value="setback">Setback</option>
            <option value="neutral">Neutral</option>
          </select>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:bg-gray-400"
        >
          {loading ? 'Recording...' : 'Record Update'}
        </button>
      </form>
    </div>
  );
}