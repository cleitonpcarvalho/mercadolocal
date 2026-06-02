import axios from 'axios'

import { useAuthStore } from '../context/AuthContext'

const api = axios.create({
  baseURL: 'http://localhost:8001',
  timeout: 30000,
})

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error?.response?.status === 401) {
      useAuthStore.getState().logout()
      if (!window.location.pathname.startsWith('/admin/login')) {
        window.location.href = '/admin/login'
      }
    }

    return Promise.reject(error)
  }
)

export function getApiErrorMessage(error, fallback = 'Nao foi possivel concluir a solicitacao.') {
  const message =
    error?.response?.data?.message ||
    error?.response?.data?.data?.detail ||
    error?.message

  if (typeof message === 'string' && message.trim()) {
    return message
  }

  return fallback
}

export default api
