import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'

import Badge from '../components/Badge'
import DataTable from '../components/DataTable'
import api, { getApiErrorMessage } from '../services/api'

const formatCurrencyBRL = (value) =>
  Number(value || 0).toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })

async function fetchProducts(params) {
  const { data } = await api.get('/api/dashboard/products/', { params })
  return data?.data || { count: 0, results: [] }
}

async function fetchStoresSelect() {
  const { data } = await api.get('/api/dashboard/stores/', { params: { page_size: 100 } })
  return data?.data?.results || []
}

function ProductsPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [store, setStore] = useState('')

  const productsQuery = useQuery({
    queryKey: ['admin-products', page, search, store],
    queryFn: () =>
      fetchProducts({
        page,
        search: search || undefined,
        store: store || undefined,
      }),
  })

  const storesQuery = useQuery({
    queryKey: ['admin-products-stores-filter'],
    queryFn: fetchStoresSelect,
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => api.patch(`/api/dashboard/products/${id}/`, payload),
    onSuccess: () => {
      toast.success('Produto atualizado com sucesso.')
      queryClient.invalidateQueries({ queryKey: ['admin-products'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const rows = productsQuery.data?.results || []
  const total = productsQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const columns = useMemo(
    () => [
      { key: 'name', label: 'Produto' },
      { key: 'store_name', label: 'Loja' },
      { key: 'price', label: 'Preco', render: (row) => formatCurrencyBRL(row.price) },
      { key: 'stock', label: 'Estoque' },
      {
        key: 'condition',
        label: 'Condicao',
        render: (row) => <Badge variant={row.condition === 'new' ? 'green' : 'amber'}>{row.condition === 'new' ? 'Novo' : 'Usado'}</Badge>,
      },
      {
        key: 'is_featured',
        label: 'Destaque',
        render: (row) => <Badge variant={row.is_featured ? 'purple' : 'gray'}>{row.is_featured ? 'Sim' : 'Nao'}</Badge>,
      },
      {
        key: 'is_available',
        label: 'Disponivel',
        render: (row) => <Badge variant={row.is_available ? 'blue' : 'red'}>{row.is_available ? 'Sim' : 'Nao'}</Badge>,
      },
      {
        key: 'actions',
        label: 'Acoes',
        render: (row) => (
          <div className="flex flex-wrap gap-2">
            <button
              className="rounded-lg bg-purple-600 px-2.5 py-1 text-xs font-bold text-white hover:bg-purple-700"
              onClick={() => updateMutation.mutate({ id: row.id, payload: { is_featured: !row.is_featured } })}
              type="button"
            >
              {row.is_featured ? 'Remover destaque' : 'Destacar'}
            </button>
            <button
              className="rounded-lg bg-gray-800 px-2.5 py-1 text-xs font-bold text-white hover:bg-gray-700"
              onClick={() => updateMutation.mutate({ id: row.id, payload: { is_available: !row.is_available } })}
              type="button"
            >
              {row.is_available ? 'Indisponivel' : 'Disponivel'}
            </button>
          </div>
        ),
      },
    ],
    [updateMutation]
  )

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm md:grid-cols-[1fr_250px]">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            className="w-full rounded-xl border border-red-100 py-2.5 pl-10 pr-3 text-sm outline-none focus:border-primary"
            onChange={(event) => {
              setPage(1)
              setSearch(event.target.value)
            }}
            placeholder="Buscar produto"
            value={search}
          />
        </div>

        <select
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setStore(event.target.value)
          }}
          value={store}
        >
          <option value="">Todas as lojas</option>
          {(storesQuery.data || []).map((item) => (
            <option key={item.id} value={item.id}>
              {item.name}
            </option>
          ))}
        </select>
      </div>

      <DataTable
        columns={columns}
        emptyMessage="Nenhum produto encontrado."
        loading={productsQuery.isLoading}
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

export default ProductsPage
