// src/GoalUpdateForm.js

import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';

export default function GoalUpdateForm({ user }) {
  const [goals, setGoals] = useState([]);
  const [selectedGoal, setSelectedGoal] = useState('');
  const [updateText, setUpdateText] = useState('');
  const [progressType, setProgressType] = useState('');
  const [statusMsg, setStatusMsg] = useState('');

  useEffect(() => {
    loadActiveGoals();
  }, []);

  async function loadActiveGoals() {
    const { data } = await supabase
      .from('goals')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false });
    setGoals(data);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const { error } = await supabase.from('goal_updates').insert({
      goal_id: selectedGoal,
      update_text: updateText,
      progress_type: progressType,
      created_by: user.id,
    });

    if (error) {
      setStatusMsg('Villa við innsendingu: ' + error.message);
    } else {
      setStatusMsg('Uppfærsla skráð.');
      setSelectedGoal('');
      setUpdateText('');
      setProgressType('');
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <h3>Uppfærsla á markmiði</h3>

      <select
        value={selectedGoal}
        onChange={(e) => setSelectedGoal(e.target.value)}
      >
        <option value="">Veldu markmið</option>
        {goals.map((g) => (
          <option key={g.id} value={g.id}>
            {g.title}
          </option>
        ))}
      </select>

      <textarea
        placeholder="Hvað gerðist?"
        value={updateText}
        onChange={(e) => setUpdateText(e.target.value)}
      />

      <label>Framvinda:</label>
      <select
        value={progressType}
        onChange={(e) => setProgressType(e.target.value)}
      >
        <option value="">Veldu tegund</option>
        <option value="improvement">Bati</option>
        <option value="setback">Bakslag</option>
        <option value="neutral">Hlutlaust</option>
      </select>

      <button type="submit">Skrá uppfærslu</button>
      <p>{statusMsg}</p>
    </form>
  );
}
