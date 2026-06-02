import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const initialState = {
  user: null,
  accessToken: null,
  refreshToken: null,
}

export const useAuthStore = create(
  persist(
    (set) => ({
      ...initialState,
      login: (payload) =>
        set({
          user: payload?.user || null,
          accessToken: payload?.access || null,
          refreshToken: payload?.refresh || null,
        }),
      updateUser: (user) => set({ user }),
      logout: () => set({ ...initialState }),
    }),
    {
      name: 'mercado-local-admin-auth',
    }
  )
)

export function useAuth() {
  const state = useAuthStore()
  return {
    user: state.user,
    accessToken: state.accessToken,
    refreshToken: state.refreshToken,
    isAuthenticated: Boolean(state.accessToken),
    isAdmin: state.user?.role === 'admin',
    login: state.login,
    updateUser: state.updateUser,
    logout: state.logout,
  }
}
