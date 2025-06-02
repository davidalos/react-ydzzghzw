// src/App.js

import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { supabase } from './supabase';

import Login from './Login';
import IncidentForm from './IncidentForm';
import IncidentDashboard from './IncidentDashboard';
import GoalsDashboard from './GoalsDashboard';
import GoalUpdateForm from './GoalUpdateForm';
import GoalProgressChart from './GoalProgressChart';

function App() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => setUser(user));
    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user || null);
      }
    );
    return () => listener?.subscription.unsubscribe();
  }, []);

  if (!user) return <Login onLogin={setUser} />;

  return (
    <Router>
      <nav style={{ padding: '1em', background: '#eee' }}>
        <Link to="/atvik" style={{ marginRight: '1em' }}>
          Atvik
        </Link>
        <Link to="/markmid" style={{ marginRight: '1em' }}>
          Markmið
        </Link>
        <Link to="/yfirlit">Yfirlit</Link>
      </nav>

      <div style={{ padding: '1em' }}>
        <Routes>
          <Route
            path="/atvik"
            element={
              <>
                <IncidentForm user={user} />
                <hr />
                <IncidentDashboard user={user} />
              </>
            }
          />
          <Route
            path="/markmid"
            element={
              <>
                <GoalsDashboard user={user} />
                <hr />
                <GoalUpdateForm user={user} />
              </>
            }
          />
          <Route path="/yfirlit" element={<GoalProgressChart />} />
          <Route path="/" element={<Login onLogin={setUser} />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
