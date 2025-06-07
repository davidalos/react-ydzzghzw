import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
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

  // Fetch incidents data
  const { data: incidents, isLoading: incidentsLoading } = useQuery({
    queryKey: ['incidents', timeRange, selectedCategory],
    queryFn: async () => {
      let query = supabase
        .from('incidents')
        .select(`
          *,
          clients(label),
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
      return data || [];
    }
  });

  // Fetch goals data
  const { data: goals, isLoading: goalsLoading } = useQuery({
    queryKey: ['goals'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('goals')
        .select(`
          *,
          clients(label),
          goal_updates(progress_type, created_at)
        `);
      
      if (error) throw error;
      return data || [];
    }
  });

  // Fetch clients data
  const { data: clients, isLoading: clientsLoading } = useQuery({
    queryKey: ['clients'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .order('label');
      
      if (error) throw error;
      return data || [];
    }
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

  const trendData = Object.entries(incidentTrends || {})
    .map(([date, count]) => ({ date, count }))
    .sort((a, b) => new Date(a.date) - new Date(b.date));

  // Calculate goal progress statistics
  const goalProgress = goals?.map(goal => {
    const updates = goal.goal_updates || [];
    const improvement = updates.filter(u => u.progress_type === 'improvement').length;
    const setback = updates.filter(u => u.progress_type === 'setback').length;
    const neutral = updates.filter(u => u.progress_type === 'neutral').length;
    
    return {
      name: goal.title.length > 20 ? goal.title.substring(0, 20) + '...' : goal.title,
      improvement,
      setback,
      neutral,
    };
  });

  const handleExportCSV = () => {
    if (!incidents) return;
    const header = ['Date', 'Category', 'Client', 'Description', 'Serious'];
    const rows = incidents.map((i) => [
      format(new Date(i.created_at), 'yyyy-MM-dd'),
      i.category,
      i.clients?.label || '',
      (i.description || '').replace(/\r?\n/g, ' '),
      i.serious ? 'Yes' : 'No'
    ]);
    const csv = [header, ...rows]
      .map((row) => row.map((f) => `"${String(f).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'incidents.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  if (incidentsLoading || goalsLoading || clientsLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Hleð gögnum...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 md:p-6 max-w-7xl mx-auto">
      <div className="mb-6 flex flex-col md:flex-row md:items-center md:justify-between">
        <h1 className="text-3xl font-bold mb-4 md:mb-0 text-gray-900">Yfirlit</h1>
        
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

          <button
            onClick={handleExportCSV}
            className="rounded-md bg-indigo-600 px-4 py-2 text-white shadow hover:bg-indigo-700 transition-colors"
          >
            Sækja CSV
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow border-l-4 border-blue-500">
          <h3 className="text-lg font-semibold text-gray-900">Heildaratvik</h3>
          <p className="text-3xl font-bold text-blue-600">{incidents?.length || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow border-l-4 border-green-500">
          <h3 className="text-lg font-semibold text-gray-900">Virk markmið</h3>
          <p className="text-3xl font-bold text-green-600">
            {goals?.filter(g => g.status === 'active').length || 0}
          </p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow border-l-4 border-yellow-500">
          <h3 className="text-lg font-semibold text-gray-900">Íbúar</h3>
          <p className="text-3xl font-bold text-yellow-600">{clients?.length || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow border-l-4 border-red-500">
          <h3 className="text-lg font-semibold text-gray-900">Alvarleg atvik</h3>
          <p className="text-3xl font-bold text-red-600">
            {incidents?.filter(i => i.serious).length || 0}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Incident Distribution */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4 text-gray-900">Dreifing atvika</h2>
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
          <h2 className="text-xl font-semibold mb-4 text-gray-900">Þróun atvika yfir tíma</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="count" stroke="#8884d8" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Goal Progress */}
      <div className="bg-white p-6 rounded-lg shadow mb-8">
        <h2 className="text-xl font-semibold mb-4 text-gray-900">Framvinda markmiða</h2>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={goalProgress}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
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
      <div className="bg-white rounded-lg shadow overflow-hidden mb-8">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Nýleg atvik</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Dagsetning
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Íbúi
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Flokkur
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Lýsing
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Alvarlegt
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {incidents?.slice(0, 10).map((incident) => (
                <tr key={incident.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {format(new Date(incident.created_at), 'dd.MM.yyyy')}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {incident.clients?.label}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                      incident.category === 'Positive Progress' ? 'bg-green-100 text-green-800' :
                      incident.category === 'Medical' ? 'bg-blue-100 text-blue-800' :
                      incident.category === 'Emergency' ? 'bg-red-100 text-red-800' :
                      incident.category === 'Safety' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {incident.category}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                    {incident.description}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {incident.serious ? (
                      <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800">
                        Já
                      </span>
                    ) : (
                      <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800">
                        Nei
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Goals Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Markmið</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Íbúi
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Markmið
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Staða
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Uppfærslur
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Búið til
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {goals?.map((goal) => (
                <tr key={goal.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {goal.clients?.label}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">
                    <div>
                      <div className="font-medium">{goal.title}</div>
                      {goal.description && (
                        <div className="text-gray-500 text-xs mt-1 max-w-xs truncate">
                          {goal.description}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                      goal.status === 'active' ? 'bg-green-100 text-green-800' :
                      goal.status === 'completed' ? 'bg-blue-100 text-blue-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {goal.status === 'active' ? 'Virkt' : 
                       goal.status === 'completed' ? 'Lokið' : 'Geymt'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {goal.goal_updates?.length || 0} uppfærslur
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format(new Date(goal.created_at), 'dd.MM.yyyy')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}