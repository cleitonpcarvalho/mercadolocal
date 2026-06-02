import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import { useSearchParams } from 'react-router-dom'

import Badge from '../components/Badge'
import DataTable from '../components/DataTable'
import api, { getApiErrorMessage } from '../services/api'

const formatDate = (value) => new Date(value).toLocaleString('pt-BR')

async function fetchStores(params) {
  const { data } = await api.get('/api/dashboard/stores/', { params })
  return data?.data || { count: 0, results: [] }
}

function StoresPage() {
  const [searchParams] = useSearchParams()
  const initialTab = searchParams.get('tab')
  const allowedTabs = new Set(['all', 'pending', 'verified', 'inactive'])
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [tab, setTab] = useState(allowedTabs.has(initialTab) ? initialTab : 'all')

  const queryParams = {
    page,
    search: search || undefined,
  }

  if (tab === 'pending') {
    queryParams.is_verified = false
  }
  if (tab === 'verified') {
    queryParams.is_verified = true
  }
  if (tab === 'inactive') {
    queryParams.is_active = false
  }

  const storesQuery = useQuery({
    queryKey: ['admin-stores', page, search, tab],
    queryFn: () => fetchStores(queryParams),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => api.patch(`/api/dashboard/stores/${id}/`, payload),
    onSuccess: () => {
      toast.success('Loja atualizada com sucesso.')
      queryClient.invalidateQueries({ queryKey: ['admin-stores'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const rows = storesQuery.data?.results || []
  const total = storesQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const columns = useMemo(
    () => [
      { key: 'name', label: 'Loja' },
      { key: 'owner_name', label: 'Responsavel' },
      { key: 'city', label: 'Cidade' },
      {
        key: 'is_verified',
        label: 'Verificada',
        render: (row) => <Badge variant={row.is_verified ? 'green' : 'amber'}>{row.is_verified ? 'Sim' : 'Pendente'}</Badge>,
      },
      {
        key: 'is_active',
        label: 'Ativa',
        render: (row) => <Badge variant={row.is_active ? 'blue' : 'red'}>{row.is_active ? 'Ativa' : 'Inativa'}</Badge>,
      },
      { key: 'commission_rate', label: 'Comissao (%)' },
      { key: 'created_at', label: 'Cadastro', render: (row) => formatDate(row.created_at) },
      {
        key: 'actions',
        label: 'Acoes',
        render: (row) => (
          <div className="flex flex-wrap gap-2">
            {!row.is_verified ? (
              <button
                className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-bold text-white hover:bg-emerald-700"
                onClick={() => updateMutation.mutate({ id: row.id, payload: { is_verified: true } })}
                type="button"
              >
                Aprovar
              </button>
            ) : null}

            <button
              className="rounded-lg bg-red-600 px-2.5 py-1 text-xs font-bold text-white hover:bg-red-700"
              onClick={() => updateMutation.mutate({ id: row.id, payload: { is_active: !row.is_active } })}
              type="button"
            >
              {row.is_active ? 'Desativar' : 'Ativar'}
            </button>

            <button
              className="rounded-lg bg-gray-800 px-2.5 py-1 text-xs font-bold text-white hover:bg-gray-700"
              onClick={() => {
                const nextCommission = window.prompt('Nova comissao (%)', row.commission_rate)
                if (!nextCommission) return
                updateMutation.mutate({
                  id: row.id,
                  payload: { commission_rate: nextCommission },
                })
              }}
              type="button"
            >
              Comissao
            </button>
          </div>
        ),
      },
    ],
    [updateMutation]
  )

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
        <div className="flex flex-wrap items-center gap-2">
          {[
            { value: 'all', label: 'Todas' },
            { value: 'pending', label: 'Pendentes' },
            { value: 'verified', label: 'Verificadas' },
            { value: 'inactive', label: 'Inativas' },
          ].map((item) => (
            <button
              key={item.value}
              className={`rounded-full px-3 py-1.5 text-xs font-bold ${
                tab === item.value ? 'bg-primary text-white' : 'bg-red-50 text-primary'
              }`}
              onClick={() => {
                setPage(1)
                setTab(item.value)
              }}
              type="button"
            >
              {item.label}
            </button>
          ))}
        </div>

        <div className="relative mt-3">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            className="w-full rounded-xl border border-red-100 py-2.5 pl-10 pr-3 text-sm outline-none focus:border-primary"
            onChange={(event) => {
              setPage(1)
              setSearch(event.target.value)
            }}
            placeholder="Buscar por nome da loja ou responsavel"
            value={search}
          />
        </div>
      </div>

      <DataTable
        columns={columns}
        emptyMessage="Nenhuma loja encontrada."
        loading={storesQuery.isLoading}
        rowClassName={(row) => (row.is_verified ? '' : 'bg-amber-50/40')}
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

export default StoresPage
