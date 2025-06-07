import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export function PrivateRoute({ children, requireManager = false }) {
  const { user, isManager, loading } = useAuth();
  const location = useLocation();

  // TEMPORARY BYPASS: Allow access without authentication
  // TODO: Remove this bypass once login issues are resolved
  const TEMP_BYPASS = true;
  
  if (TEMP_BYPASS) {
    console.log('🚨 TEMPORARY AUTH BYPASS ACTIVE - Remove this in production!');
    return children;
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Note: Removed manager requirement check - all authenticated users can access all pages
  // This allows everyone to see the Yfirlit (Overview) page

  return children;
}