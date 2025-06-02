// src/GoalProgressChart.js

import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';
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

  useEffect(() => {
    loadChartData();
  }, []);

  async function loadChartData() {
    // Step 1: Fetch all goals
    const { data: goals } = await supabase.from('goals').select('id, title');

    // Step 2: Fetch all goal updates
    const { data: updates } = await supabase
      .from('goal_updates')
      .select('goal_id, progress_type');

    // Step 3: Count progress types per goal
    const summary = goals.map((goal) => {
      const updatesForGoal = updates.filter((u) => u.goal_id === goal.id);
      return {
        name: goal.title,
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
  }

  return (
    <div>
      <h3>Framvinda markmiða</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data}>
          <XAxis dataKey="name" />
          <YAxis allowDecimals={false} />
          <Tooltip />
          <Legend />
          <Bar dataKey="improvement" fill="#4caf50" name="Bati" />
          <Bar dataKey="setback" fill="#f44336" name="Bakslag" />
          <Bar dataKey="neutral" fill="#9e9e9e" name="Hlutlaust" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
