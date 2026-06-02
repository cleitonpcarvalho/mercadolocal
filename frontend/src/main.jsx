import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "react-hot-toast";

import App from "./App.jsx";
import { AuthProvider } from "./context/AuthContext.jsx";
import "./index.css";
import "./utils/leaflet";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
      refetchOnWindowFocus: false,
    },
  },
});

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <App />
          <Toaster position="top-right" />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>
);
