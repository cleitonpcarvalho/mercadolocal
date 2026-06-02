import { Navigate } from "react-router-dom";

import { useAuth } from "../context/AuthContext";

function StoreOwnerRoute({ children }) {
  const { isAuthenticated, user } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (user?.role !== "store_owner") {
    return <Navigate to="/" replace />;
  }

  return children;
}

export default StoreOwnerRoute;
