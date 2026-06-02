import { useQuery } from '@tanstack/react-query'
import { useMemo, useState } from 'react'

import Badge from '../components/Badge'
import DataTable from '../components/DataTable'
import api from '../services/api'

const formatDate = (value) => new Date(value).toLocaleString('pt-BR')
const formatCurrencyBRL = (value) =>
  Number(value || 0).toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })

async function fetchOrders(params) {
  const { data } = await api.get('/api/dashboard/orders/', { params })
  return data?.data || { count: 0, results: [] }
}

function OrdersPage() {
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const [paymentStatus, setPaymentStatus] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  const ordersQuery = useQuery({
    queryKey: ['admin-orders', page, status, paymentStatus, startDate, endDate],
    queryFn: () =>
      fetchOrders({
        page,
        status: status || undefined,
        payment_status: paymentStatus || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
      }),
  })

  const rows = ordersQuery.data?.results || []
  const total = ordersQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const columns = useMemo(
    () => [
      { key: 'id', label: 'Pedido', render: (row) => `#${row.id}` },
      { key: 'customer_name', label: 'Cliente' },
      { key: 'store_name', label: 'Loja' },
      { key: 'total', label: 'Total', render: (row) => formatCurrencyBRL(row.total) },
      {
        key: 'status',
        label: 'Status',
        render: (row) => <Badge variant="blue">{row.status}</Badge>,
      },
      {
        key: 'payment_status',
        label: 'Pagamento',
        render: (row) => <Badge variant={row.payment_status === 'paid' ? 'green' : 'amber'}>{row.payment_status}</Badge>,
      },
      { key: 'created_at', label: 'Criado em', render: (row) => formatDate(row.created_at) },
    ],
    []
  )

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm md:grid-cols-4">
        <select
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setStatus(event.target.value)
          }}
          value={status}
        >
          <option value="">Todos status</option>
          <option value="pending">pending</option>
          <option value="confirmed">confirmed</option>
          <option value="preparing">preparing</option>
          <option value="ready">ready</option>
          <option value="in_delivery">in_delivery</option>
          <option value="delivered">delivered</option>
          <option value="cancelled">cancelled</option>
        </select>

        <select
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setPaymentStatus(event.target.value)
          }}
          value={paymentStatus}
        >
          <option value="">Todos pagamentos</option>
          <option value="pending">pending</option>
          <option value="paid">paid</option>
          <option value="failed">failed</option>
          <option value="refunded">refunded</option>
        </select>

        <input
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setStartDate(event.target.value)
          }}
          type="date"
          value={startDate}
        />

        <input
          className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
          onChange={(event) => {
            setPage(1)
            setEndDate(event.target.value)
          }}
          type="date"
          value={endDate}
        />
      </div>

      <DataTable
        columns={columns}
        emptyMessage="Nenhum pedido encontrado."
        loading={ordersQuery.isLoading}
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

export default OrdersPage
