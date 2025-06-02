import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';

import Login from './Login';
import IncidentForm from './IncidentForm';
import IncidentDashboard from './IncidentDashboard';
import GoalsDashboard from './GoalsDashboard';
import GoalUpdateForm from './GoalUpdateForm';
import GoalProgressChart from './GoalProgressChart';
import { PrivateRoute } from './components/PrivateRoute';

function App() {
  return (
    <Router>
      <Toaster position="top-right" />
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route
          path="/atvik"
          element={
            <PrivateRoute>
              <>
                <IncidentForm />
                <hr />
                <IncidentDashboard />
              </>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/markmid"
          element={
            <PrivateRoute>
              <>
                <GoalsDashboard />
                <hr />
                <GoalUpdateForm />
              </>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/yfirlit"
          element={
            <PrivateRoute requireManager={true}>
              <GoalProgressChart />
            </PrivateRoute>
          }
        />
        
        <Route path="/" element={<Login />} />
      </Routes>
    </Router>
  );
}

export default App;