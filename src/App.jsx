import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import Login from './Login.jsx';
import SignUp from './SignUp.jsx';
import Home from './Home.jsx';
import IncidentForm from './IncidentForm.jsx';
import IncidentDashboard from './IncidentDashboard.jsx';
import GoalsDashboard from './GoalsDashboard.jsx';
import GoalUpdateForm from './GoalUpdateForm.jsx';
import GoalProgressChart from './GoalProgressChart.jsx';
import Unauthorized from './Unauthorized.jsx';
import { ManagerDashboard } from './components/ManagerDashboard.jsx';
import Yfirlit from './Yfirlit.jsx';
import { PrivateRoute } from './components/PrivateRoute.jsx';
import { Navigation } from './components/Navigation.jsx';
import { DataPrivacyNotice } from './components/DataPrivacyNotice.jsx';
import { useAuth } from './hooks/useAuth';
import { useDataPrivacy } from './hooks/useDataPrivacy';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
    },
  },
});

function App() {
  const { loading } = useAuth();
  const { hasAcceptedPrivacy, showPrivacyNotice, acceptPrivacy, declinePrivacy } = useDataPrivacy();

  // TEMPORARY BYPASS: Skip loading check
  const TEMP_BYPASS = true;
  
  if (loading && !TEMP_BYPASS) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <Toaster position="top-right" />
        
        {/* TEMPORARY BYPASS NOTICE */}
        {TEMP_BYPASS && (
          <div className="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 text-center">
            <p className="font-bold">🚨 TEMPORARY AUTH BYPASS ACTIVE</p>
            <p className="text-sm">Authentication is disabled for testing. Remove this in production!</p>
          </div>
        )}
        
        <div className="min-h-screen bg-gray-50">
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<SignUp />} />
            <Route path="/unauthorized" element={<Unauthorized />} />
            <Route
              path="/*"
              element={
                <PrivateRoute>
                  <>
                    <Navigation />
                    <div className="container mx-auto px-4 py-8">
                      <Routes>
                        <Route path="/\" element={<Home />} />
                        <Route
                          path="/atvik"
                          element={
                            <>
                              <IncidentForm />
                              <hr className="my-8" />
                              <IncidentDashboard />
                            </>
                          }
                        />
                        <Route
                          path="/markmid"
                          element={
                            <>
                              <GoalsDashboard />
                              <hr className="my-8" />
                              <GoalUpdateForm />
                              <hr className="my-8" />
                              <GoalProgressChart />
                            </>
                          }
                        />
                        <Route
                          path="/yfirlit"
                          element={<Yfirlit />}
                        />
                      </Routes>
                    </div>
                  </>
                </PrivateRoute>
              }
            />
          </Routes>
        </div>
        
        {/* Data Privacy Notice */}
        <DataPrivacyNotice
          isVisible={showPrivacyNotice && !TEMP_BYPASS}
          onAccept={acceptPrivacy}
          onDecline={declinePrivacy}
        />
      </Router>
    </QueryClientProvider>
  );
}

export default App;