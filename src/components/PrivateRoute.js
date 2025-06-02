import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export function PrivateRoute({ children, requireManager = false }) {
  const { user, isManager, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (requireManager && !isManager) {
    return <Navigate to="/unauthorized" state={{ from: location }} replace />;
  }

  return children;
}