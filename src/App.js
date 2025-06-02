import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { QueryClient, QueryClientProvider } from 'react-query';

import Login from './Login';
import IncidentForm from './IncidentForm';
import IncidentDashboard from './IncidentDashboard';
import GoalsDashboard from './GoalsDashboard';
import GoalUpdateForm from './GoalUpdateForm';
import GoalProgressChart from './GoalProgressChart';
import { ManagerDashboard } from './components/ManagerDashboard';
import { PrivateRoute } from './components/PrivateRoute';
import { useAuth } from './hooks/useAuth';

const queryClient = new QueryClient();

function App() {
  const { loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <Toaster position="top-right" />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<Navigate to="/atvik" replace />} />
          
          <Route
            path="/atvik"
            element={
              <PrivateRoute>
                <div className="container mx-auto px-4 py-8">
                  <IncidentForm />
                  <hr className="my-8" />
                  <IncidentDashboard />
                </div>
              </PrivateRoute>
            }
          />
          
          <Route
            path="/markmid"
            element={
              <PrivateRoute>
                <div className="container mx-auto px-4 py-8">
                  <GoalsDashboard />
                  <hr className="my-8" />
                  <GoalUpdateForm />
                </div>
              </PrivateRoute>
            }
          />
          
          <Route
            path="/yfirlit"
            element={
              <PrivateRoute requireManager={true}>
                <ManagerDashboard />
              </PrivateRoute>
            }
          />

          <Route path="/unauthorized" element={
            <div className="min-h-screen flex items-center justify-center">
              <div className="text-center">
                <h1 className="text-2xl font-bold text-gray-900">Unauthorized Access</h1>
                <p className="mt-2 text-gray-600">You don't have permission to access this page.</p>
              </div>
            </div>
          } />
        </Routes>
      </Router>
    </QueryClientProvider>
  );
}

export default App;