import api from './api'

export async function loginRequest(payload) {
  const { data } = await api.post('/api/users/login/', payload)
  return data
}

export async function logoutRequest(refreshToken) {
  const { data } = await api.post('/api/users/logout/', { refresh: refreshToken })
  return data
}

export async function getMeRequest() {
  const { data } = await api.get('/api/users/me/')
  return data
}
