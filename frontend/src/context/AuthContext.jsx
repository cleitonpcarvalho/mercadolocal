/* eslint-disable react-refresh/only-export-components */

import { createContext, useContext } from "react";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

const AuthContext = createContext(null);

export const useAuthStore = create(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,

      login: ({ access, refresh, user }) => {
        localStorage.setItem("accessToken", access);
        localStorage.setItem("refreshToken", refresh);
        localStorage.setItem("user", JSON.stringify(user));

        set({
          user,
          accessToken: access,
          refreshToken: refresh,
          isAuthenticated: true,
        });
      },

      logout: () => {
        localStorage.removeItem("accessToken");
        localStorage.removeItem("refreshToken");
        localStorage.removeItem("user");

        set({
          user: null,
          accessToken: null,
          refreshToken: null,
          isAuthenticated: false,
        });
      },

      updateProfile: (payload) => {
        set((state) => {
          const nextUser = { ...(state.user || {}), ...payload };
          localStorage.setItem("user", JSON.stringify(nextUser));
          return { user: nextUser };
        });
      },
    }),
    {
      name: "auth-storage",
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        user: state.user,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

export function AuthProvider({ children }) {
  const authState = useAuthStore((state) => state);
  return <AuthContext.Provider value={authState}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const contextValue = useContext(AuthContext);
  const storeValue = useAuthStore((state) => state);
  return contextValue ?? storeValue;
}
