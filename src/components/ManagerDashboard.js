import React from 'react';
import { useQuery } from 'react-query';
import { supabase } from '../supabase';
import { format } from 'date-fns';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

export function ManagerDashboard() {
  const { data: incidents } = useQuery('incidents', async () => {
    const { data, error } = await supabase
      .from('incidents')
      .select(`
        *,
        user_profiles!incidents_submitted_by_fkey(full_name)
      `)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  });

  const { data: goals } = useQuery('goals', async () => {
    const { data, error } = await supabase
      .from('goals')
      .select(`
        *,
        goal_updates(progress_type)
      `);
    
    if (error) throw error;
    return data;
  });

  // Calculate incident statistics
  const incidentsByCategory = incidents?.reduce((acc, incident) => {
    acc[incident.category] = (acc[incident.category] || 0) + 1;
    return acc;
  }, {});

  const incidentChartData = Object.entries(incidentsByCategory || {}).map(([name, value]) => ({
    name,
    value,
  }));

  // Calculate goal progress statistics
  const goalProgress = goals?.map(goal => {
    const updates = goal.goal_updates || [];
    const improvement = updates.filter(u => u.progress_type === 'improvement').length;
    const setback = updates.filter(u => u.progress_type === 'setback').length;
    const neutral = updates.filter(u => u.progress_type === 'neutral').length;
    
    return {
      name: goal.title,
      improvement,
      setback,
      neutral,
    };
  });

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Manager Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Incident Distribution */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Incident Distribution</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={incidentChartData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label
                >
                  {incidentChartData?.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Goal Progress */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Goal Progress</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={goalProgress}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="improvement" fill="#4caf50" name="Improvement" />
                <Bar dataKey="setback" fill="#f44336" name="Setback" />
                <Bar dataKey="neutral" fill="#9e9e9e" name="Neutral" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Incidents */}
        <div className="bg-white p-6 rounded-lg shadow md:col-span-2">
          <h2 className="text-lg font-semibold mb-4">Recent Incidents</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Category
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Submitted By
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Description
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {incidents?.slice(0, 5).map((incident) => (
                  <tr key={incident.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(incident.created_at), 'PPP')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {incident.category}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {incident.user_profiles?.full_name}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {incident.description}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}