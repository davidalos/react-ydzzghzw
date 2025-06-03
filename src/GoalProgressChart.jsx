import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
import toast from 'react-hot-toast';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

export default function GoalProgressChart() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadChartData();
  }, []);

  async function loadChartData() {
    try {
      // Step 1: Fetch all active goals
      const { data: goals, error: goalsError } = await supabase
        .from('goals')
        .select('id, title, clients(label)')
        .eq('status', 'active');

      if (goalsError) throw goalsError;

      // Step 2: Fetch all goal updates
      const { data: updates, error: updatesError } = await supabase
        .from('goal_updates')
        .select('goal_id, progress_type');

      if (updatesError) throw updatesError;

      // Step 3: Count progress types per goal
      const summary = goals.map((goal) => {
        const updatesForGoal = updates.filter((u) => u.goal_id === goal.id);
        return {
          name: `${goal.title} (${goal.clients?.label})`,
          improvement: updatesForGoal.filter(
            (u) => u.progress_type === 'improvement'
          ).length,
          setback: updatesForGoal.filter((u) => u.progress_type === 'setback')
            .length,
          neutral: updatesForGoal.filter((u) => u.progress_type === 'neutral')
            .length,
        };
      });

      setData(summary);
    } catch (error) {
      toast.error('Failed to load goal progress data');
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

  if (data.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold mb-4">Goal Progress</h2>
        <p className="text-gray-500">No active goals found.</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-2xl font-bold mb-4">Goal Progress</h2>
      <div className="h-96">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
            <YAxis allowDecimals={false} />
            <Tooltip />
            <Legend />
            <Bar dataKey="improvement" fill="#4caf50" name="Improvement" />
            <Bar dataKey="setback" fill="#f44336" name="Setback" />
            <Bar dataKey="neutral" fill="#9e9e9e" name="Neutral" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}