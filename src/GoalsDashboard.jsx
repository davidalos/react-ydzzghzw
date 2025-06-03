// src/GoalsDashboard.js

import React, { useEffect, useState } from 'react';
import { supabase } from './supabase';

export default function GoalsDashboard({ user }) {
  const [clients, setClients] = useState([]);
  const [goals, setGoals] = useState([]);
  const [newGoal, setNewGoal] = useState({
    client_id: '',
    title: '',
    description: '',
  });
  const [statusMsg, setStatusMsg] = useState('');

  useEffect(() => {
    loadClients();
    loadGoals();
  }, []);

  async function loadClients() {
    const { data } = await supabase.from('clients').select('*');
    setClients(data);
  }

  async function loadGoals() {
    const { data } = await supabase
      .from('goals')
      .select('*')
      .order('created_at', { ascending: false });
    setGoals(data);
  }

  async function handleCreateGoal(e) {
    e.preventDefault();
    const { error } = await supabase.from('goals').insert({
      client_id: newGoal.client_id,
      title: newGoal.title,
      description: newGoal.description,
      created_by: user.id,
    });

    if (error) {
      setStatusMsg('Villa við að skrá markmið: ' + error.message);
    } else {
      setStatusMsg('Markmið skráð.');
      setNewGoal({ client_id: '', title: '', description: '' });
      loadGoals();
    }
  }

  async function changeGoalStatus(goalId, newStatus) {
    await supabase.from('goals').update({ status: newStatus }).eq('id', goalId);
    loadGoals();
  }

  return (
    <div>
      <h2>Markmið fyrir Íbúa</h2>

      <form onSubmit={handleCreateGoal}>
        <h4>Nýtt markmið</h4>
        <select
          value={newGoal.client_id}
          onChange={(e) =>
            setNewGoal({ ...newGoal, client_id: e.target.value })
          }
        >
          <option value="">Veldu íbúa</option>
          {clients.map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </select>
        <input
          type="text"
          placeholder="Heiti markmiðs"
          value={newGoal.title}
          onChange={(e) => setNewGoal({ ...newGoal, title: e.target.value })}
        />
        <textarea
          placeholder="Lýsing markmiðs"
          value={newGoal.description}
          onChange={(e) =>
            setNewGoal({ ...newGoal, description: e.target.value })
          }
        />
        <button type="submit">Skrá</button>
        <p>{statusMsg}</p>
      </form>

      <h4>Öll markmið</h4>
      {goals.map((goal) => (
        <div
          key={goal.id}
          style={{
            border: '1px solid #ccc',
            margin: '1em 0',
            padding: '0.5em',
          }}
        >
          <strong>{goal.title}</strong> — {goal.status}
          <p>{goal.description}</p>
          <button onClick={() => changeGoalStatus(goal.id, 'completed')}>
            ✓ Lokið
          </button>
          <button onClick={() => changeGoalStatus(goal.id, 'archived')}>
            🗂️ Taka úr umferð
          </button>
        </div>
      ))}
    </div>
  );
}
