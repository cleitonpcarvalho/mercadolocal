import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'

import Badge from '../components/Badge'
import DataTable from '../components/DataTable'
import api, { getApiErrorMessage } from '../services/api'

const roleLabels = {
  customer: 'Cliente',
  store_owner: 'Lojista',
  delivery_driver: 'Entregador',
  admin: 'Admin',
}

const roleBadge = {
  customer: 'blue',
  store_owner: 'purple',
  delivery_driver: 'amber',
  admin: 'red',
}

const formatDate = (value) => new Date(value).toLocaleString('pt-BR')

async function fetchUsers(params) {
  const { data } = await api.get('/api/dashboard/users/', { params })
  return data?.data || { count: 0, results: [] }
}

function UsersPage() {
  const queryClient = useQueryClient()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [role, setRole] = useState('')

  const usersQuery = useQuery({
    queryKey: ['admin-users', page, role, search],
    queryFn: () =>
      fetchUsers({
        page,
        role: role || undefined,
        search: search || undefined,
      }),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => api.patch(`/api/dashboard/users/${id}/`, payload),
    onSuccess: () => {
      toast.success('Usuario atualizado com sucesso.')
      queryClient.invalidateQueries({ queryKey: ['admin-users'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const rows = usersQuery.data?.results || []
  const total = usersQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const columns = useMemo(
    () => [
      { key: 'name', label: 'Nome', render: (row) => row.name || '-' },
      { key: 'email', label: 'Email' },
      {
        key: 'role',
        label: 'Perfil',
        render: (row) => <Badge variant={roleBadge[row.role]}>{roleLabels[row.role] || row.role}</Badge>,
      },
      { key: 'city', label: 'Cidade', render: (row) => `${row.city || '-'} / ${row.state || '-'}` },
      {
        key: 'is_verified',
        label: 'Verificado',
        render: (row) => <Badge variant={row.is_verified ? 'green' : 'amber'}>{row.is_verified ? 'Sim' : 'Nao'}</Badge>,
      },
      { key: 'created_at', label: 'Cadastro', render: (row) => formatDate(row.created_at) },
      {
        key: 'actions',
        label: 'Acoes',
        render: (row) => (
          <button
            className={`rounded-lg px-3 py-1.5 text-xs font-bold text-white ${
              row.is_active ? 'bg-red-600 hover:bg-red-700' : 'bg-emerald-600 hover:bg-emerald-700'
            }`}
            onClick={() => updateMutation.mutate({ id: row.id, payload: { is_active: !row.is_active } })}
            type="button"
          >
            {row.is_active ? 'Desativar' : 'Ativar'}
          </button>
        ),
      },
    ],
    [updateMutation]
  )

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm md:grid-cols-[1fr_220px]">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            className="w-full rounded-xl border border-red-100 py-2.5 pl-10 pr-3 text-sm outline-none focus:border-primary"
            onChange={(event) => {
              setPage(1)
              setSearch(event.target.value)
            }}
            placeholder="Buscar por nome ou email"
            value={search}
          />
        </div>

        <select
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setRole(event.target.value)
          }}
          value={role}
        >
          <option value="">Todos os perfis</option>
          <option value="customer">Clientes</option>
          <option value="store_owner">Lojistas</option>
          <option value="delivery_driver">Entregadores</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        emptyMessage="Nenhum usuario encontrado."
        loading={usersQuery.isLoading}
        rows={rows}
      />

      <div className="flex items-center justify-end gap-2">
        <button
          className="rounded-lg border border-red-100 px-3 py-2 text-sm font-semibold text-gray-700 disabled:opacity-50"
          disabled={page <= 1}
          onClick={() => setPage((state) => state - 1)}
          type="button"
        >
          Anterior
        </button>
        <span className="text-sm font-semibold text-gray-600">
          Pagina {page} de {totalPages}
        </span>
        <button
          className="rounded-lg border border-red-100 px-3 py-2 text-sm font-semibold text-gray-700 disabled:opacity-50"
          disabled={page >= totalPages}
          onClick={() => setPage((state) => state + 1)}
          type="button"
        >
          Proxima
        </button>
      </div>
    </div>
  )
}

export default UsersPage
