import { useQuery } from '@tanstack/react-query'
import { useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import Badge from '../components/Badge'
import DataTable from '../components/DataTable'
import api from '../services/api'

const formatDate = (value) => (value ? new Date(value).toLocaleString('pt-BR') : '-')

async function fetchDeliveries(params) {
  const { data } = await api.get('/api/dashboard/deliveries/', { params })
  return data?.data || { count: 0, results: [] }
}

function DeliveriesPage() {
  const [searchParams] = useSearchParams()
  const initialStatus = searchParams.get('status') || ''
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState(initialStatus)
  const [city, setCity] = useState('')

  const deliveriesQuery = useQuery({
    queryKey: ['admin-deliveries', page, status, city],
    queryFn: () =>
      fetchDeliveries({
        page,
        status: status || undefined,
        city: city || undefined,
      }),
  })

  const rows = deliveriesQuery.data?.results || []
  const total = deliveriesQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const columns = useMemo(
    () => [
      { key: 'id', label: 'Entrega', render: (row) => `#${row.id}` },
      { key: 'order_id', label: 'Pedido', render: (row) => `#${row.order_id}` },
      { key: 'driver_name', label: 'Entregador', render: (row) => row.driver_name || 'Nao atribuido' },
      { key: 'status', label: 'Status', render: (row) => <Badge variant="blue">{row.status}</Badge> },
      { key: 'created_at', label: 'Criada em', render: (row) => formatDate(row.created_at) },
      { key: 'delivered_at', label: 'Entregue em', render: (row) => formatDate(row.delivered_at) },
    ],
    []
  )

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm md:grid-cols-2">
        <select
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setStatus(event.target.value)
          }}
          value={status}
        >
          <option value="">Todos status</option>
          <option value="waiting">waiting</option>
          <option value="accepted">accepted</option>
          <option value="picked_up">picked_up</option>
          <option value="delivered">delivered</option>
          <option value="failed">failed</option>
        </select>

        <input
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setCity(event.target.value)
          }}
          placeholder="Filtrar por cidade"
          value={city}
        />
      </div>

      <DataTable
        columns={columns}
        emptyMessage="Nenhuma entrega encontrada."
        loading={deliveriesQuery.isLoading}
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

export default DeliveriesPage
