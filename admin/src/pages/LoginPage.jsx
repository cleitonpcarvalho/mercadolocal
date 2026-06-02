import { useMutation } from '@tanstack/react-query'
import { LogIn } from 'lucide-react'
import { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'

import { useAuth } from '../context/AuthContext'
import { loginRequest } from '../services/auth'
import { getApiErrorMessage } from '../services/api'

function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [form, setForm] = useState({ email: '', password: '' })

  useEffect(() => {
    const hash = window.location.hash || ''
    if (!hash.startsWith('#auth=')) return

    try {
      const encoded = hash.replace('#auth=', '')
      const authData = JSON.parse(decodeURIComponent(encoded))
      if (authData?.user?.role !== 'admin') {
        toast.error('Acesso restrito ao administrador')
        return
      }

      login(authData)
      window.history.replaceState(null, '', window.location.pathname)
      navigate('/dashboard', { replace: true })
    } catch (error) {
      toast.error('Nao foi possivel validar o acesso administrativo.')
    }
  }, [login, navigate])

  const mutation = useMutation({
    mutationFn: loginRequest,
    onSuccess: (payload) => {
      const authData = payload?.data || {}
      const role = authData?.user?.role

      if (role !== 'admin') {
        toast.error('Acesso restrito ao administrador')
        return
      }

      login(authData)
      toast.success(payload?.message || 'Login realizado com sucesso!')
      navigate('/dashboard', { replace: true })
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, 'Nao foi possivel fazer login.'))
    },
  })

  const onSubmit = (event) => {
    event.preventDefault()
    mutation.mutate(form)
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-b from-red-50 to-white px-4 py-10">
      <div className="w-full max-w-md rounded-3xl border border-red-100 bg-white p-7 shadow-lg">
        <img
          alt="Mercado Local"
          className="mx-auto mb-4 h-14 w-auto"
          src="/logo-mercado-local-horizontal-sem-fundo.png"
        />
        <h1 className="text-2xl font-extrabold text-gray-900">Admin Mercado Local</h1>
        <p className="mt-1 text-sm text-gray-500">Acesse com sua conta de administrador</p>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <input
            className="w-full rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            onChange={(event) => setForm((state) => ({ ...state, email: event.target.value }))}
            placeholder="Email"
            required
            type="email"
            value={form.email}
          />
          <input
            className="w-full rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            minLength={8}
            onChange={(event) => setForm((state) => ({ ...state, password: event.target.value }))}
            placeholder="Senha"
            required
            type="password"
            value={form.password}
          />

          <button
            className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700 disabled:opacity-60"
            disabled={mutation.isPending}
            type="submit"
          >
            <LogIn className="h-4 w-4" />
            {mutation.isPending ? 'Entrando...' : 'Entrar'}
          </button>
        </form>
      </div>
    </div>
  )
}

export default LoginPage
