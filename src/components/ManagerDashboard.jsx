import React, { useState } from 'react';
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
  LineChart,
  Line,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

export function ManagerDashboard() {
  const [timeRange, setTimeRange] = useState('month');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const { data: incidents } = useQuery(['incidents', timeRange, selectedCategory], async () => {
    let query = supabase
      .from('incidents')
      .select(`
        *,
        user_profiles!incidents_submitted_by_fkey(full_name)
      `)
      .order('created_at', { ascending: false });

    // Apply time range filter
    const now = new Date();
    if (timeRange === 'week') {
      query = query.gte('created_at', new Date(now.setDate(now.getDate() - 7)).toISOString());
    } else if (timeRange === 'month') {
      query = query.gte('created_at', new Date(now.setMonth(now.getMonth() - 1)).toISOString());
    }

    // Apply category filter
    if (selectedCategory !== 'all') {
      query = query.eq('category', selectedCategory);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  });

  const { data: goals } = useQuery('goals', async () => {
    const { data, error } = await supabase
      .from('goals')
      .select(`
        *,
        goal_updates(progress_type, created_at)
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

  // Calculate incident trends over time
  const incidentTrends = incidents?.reduce((acc, incident) => {
    const date = format(new Date(incident.created_at), 'yyyy-MM-dd');
    acc[date] = (acc[date] || 0) + 1;
    return acc;
  }, {});

  const trendData = Object.entries(incidentTrends || {}).map(([date, count]) => ({
    date,
    count,
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
    <div className="p-4 md:p-6">
      <div className="mb-6 flex flex-col md:flex-row md:items-center md:justify-between">
        <h1 className="text-2xl font-bold mb-4 md:mb-0">Yfirlit stjórnanda</h1>
        
        <div className="flex flex-col md:flex-row gap-4">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          >
            <option value="week">Síðasta vika</option>
            <option value="month">Síðasti mánuður</option>
            <option value="all">Allt tímabil</option>
          </select>

          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          >
            <option value="all">Allir flokkar</option>
            <option value="Positive Progress">Jákvæð þróun</option>
            <option value="Medical">Læknisfræðilegt</option>
            <option value="Behavioral">Hegðun</option>
            <option value="Safety">Öryggi</option>
            <option value="Emergency">Neyðartilvik</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Incident Distribution */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Dreifing atvika</h2>
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

        {/* Incident Trends */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Þróun atvika yfir tíma</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="count" stroke="#8884d8" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Goal Progress */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-lg font-semibold mb-4">Framvinda markmiða</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={goalProgress}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="improvement" fill="#4caf50" name="Bati" />
                <Bar dataKey="setback" fill="#f44336" name="Bakslag" />
                <Bar dataKey="neutral" fill="#9e9e9e" name="Hlutlaust" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Incidents Table */}
        <div className="bg-white p-6 rounded-lg shadow md:col-span-2">
          <h2 className="text-lg font-semibold mb-4">Nýleg atvik</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead>
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Dagsetning
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Flokkur
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Skráð af
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Lýsing
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {incidents?.slice(0, 5).map((incident) => (
                  <tr key={incident.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(incident.created_at), 'dd.MM.yyyy')}
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