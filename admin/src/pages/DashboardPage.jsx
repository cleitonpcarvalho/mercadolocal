import { useQuery } from '@tanstack/react-query'
import { AlertCircle, Bike } from 'lucide-react'
import { Link } from 'react-router-dom'
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'

import StatCard from '../components/StatCard'
import api from '../services/api'

const formatCurrencyBRL = (value) =>
  Number(value || 0).toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  })

async function fetchStats() {
  const { data } = await api.get('/api/dashboard/stats/')
  return data?.data || {}
}

function DashboardPage() {
  const statsQuery = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: fetchStats,
  })

  const stats = statsQuery.data || {}

  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Total Clientes" value={stats.total_users ?? 0} />
        <StatCard label="Total Lojistas" value={stats.total_store_owners ?? 0} />
        <StatCard label="Total Lojas" value={stats.total_stores ?? 0} />
        <StatCard label="Total Produtos" value={stats.total_products ?? 0} />
        <StatCard label="Total Pedidos" value={stats.total_orders ?? 0} />
        <StatCard label="Pedidos Hoje" value={stats.total_orders_today ?? 0} />
        <StatCard label="Receita Hoje (R$)" value={formatCurrencyBRL(stats.revenue_today)} highlight />
        <StatCard label="Receita Total (R$)" value={formatCurrencyBRL(stats.revenue_total)} highlight />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <article className="rounded-2xl border border-amber-200 bg-amber-50 p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-amber-700">Lojas Aguardando Aprovacao</p>
              <p className="mt-1 text-3xl font-black text-amber-900">{stats.pending_stores ?? 0}</p>
            </div>
            <AlertCircle className="h-8 w-8 text-amber-700" />
          </div>
          <Link className="mt-4 inline-block text-sm font-bold text-amber-800 hover:underline" to="/stores?tab=pending">
            Ir para lojas pendentes
          </Link>
        </article>

        <article className="rounded-2xl border border-blue-200 bg-blue-50 p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-blue-700">Entregas Ativas</p>
              <p className="mt-1 text-3xl font-black text-blue-900">{stats.active_deliveries ?? 0}</p>
            </div>
            <Bike className="h-8 w-8 text-blue-700" />
          </div>
          <Link className="mt-4 inline-block text-sm font-bold text-blue-800 hover:underline" to="/deliveries?status=accepted">
            Ver entregas em andamento
          </Link>
        </article>
      </div>

      <article className="rounded-2xl border border-red-100 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-bold text-gray-900">Receita dos ultimos 7 dias</h2>
        <div className="mt-4 h-72">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={stats.revenue_last_7_days || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
              <XAxis dataKey="date" tick={{ fill: '#6B7280', fontSize: 12 }} />
              <YAxis tick={{ fill: '#6B7280', fontSize: 12 }} />
              <Tooltip formatter={(value) => formatCurrencyBRL(value)} />
              <Bar dataKey="amount" fill="#E8000D" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </article>

      {statsQuery.isLoading ? (
        <div className="rounded-2xl border border-red-100 bg-white p-6 text-sm text-gray-500">Carregando indicadores...</div>
      ) : null}
    </div>
  )
}

export default DashboardPage
