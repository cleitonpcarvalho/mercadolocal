import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Megaphone, PlusCircle } from 'lucide-react'
import { useState } from 'react'
import toast from 'react-hot-toast'

import Badge from '../components/Badge'
import api, { getApiErrorMessage } from '../services/api'

const adTypeLabel = {
  banner: 'Banner',
  featured_product: 'Produto em destaque',
  sponsored_store: 'Loja patrocinada',
}

const resolveImageUrl = (value) => {
  const raw = (value || '').trim()
  if (!raw) return ''
  if (raw.startsWith('http')) return raw
  return `http://localhost:8001/${raw.replace(/^\/+/, '')}`
}

async function fetchAds(params) {
  const { data } = await api.get('/api/dashboard/ads/', { params })
  return data?.data || { count: 0, results: [] }
}

function AdsPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState({
    title: '',
    description: '',
    image: '',
    ad_type: 'banner',
    starts_at: '',
    ends_at: '',
  })

  const adsQuery = useQuery({
    queryKey: ['admin-ads', page],
    queryFn: () => fetchAds({ page }),
  })

  const createMutation = useMutation({
    mutationFn: (payload) => api.post('/api/dashboard/ads/', payload),
    onSuccess: () => {
      toast.success('Anuncio da plataforma criado com sucesso.')
      setOpen(false)
      setForm({
        title: '',
        description: '',
        image: '',
        ad_type: 'banner',
        starts_at: '',
        ends_at: '',
      })
      queryClient.invalidateQueries({ queryKey: ['admin-ads'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => api.patch(`/api/dashboard/ads/${id}/`, payload),
    onSuccess: () => {
      toast.success('Anuncio atualizado com sucesso.')
      queryClient.invalidateQueries({ queryKey: ['admin-ads'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const rows = adsQuery.data?.results || []
  const total = adsQuery.data?.count || 0
  const totalPages = Math.max(1, Math.ceil(total / 20))

  const onSubmit = (event) => {
    event.preventDefault()
    createMutation.mutate(form)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-black text-gray-900">Anuncios</h2>
        <button
          className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
          onClick={() => setOpen(true)}
          type="button"
        >
          <PlusCircle className="h-4 w-4" />
          Criar Anuncio da Plataforma
        </button>
      </div>

      {rows.length === 0 && !adsQuery.isLoading ? (
        <div className="rounded-2xl border border-red-100 bg-white p-6 text-sm text-gray-500 shadow-sm">
          Nenhum anuncio cadastrado.
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {rows.map((ad) => (
          <article className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm" key={ad.id}>
            <div className="flex items-center justify-between gap-2">
              <p className="line-clamp-1 text-base font-bold text-gray-900">{ad.title}</p>
              <Badge variant={ad.is_active ? 'green' : 'red'}>{ad.is_active ? 'Ativo' : 'Inativo'}</Badge>
            </div>
            <p className="mt-1 text-xs uppercase text-gray-500">{ad.store_name || 'Plataforma'}</p>
            <p className="mt-3 text-sm text-gray-600">{ad.description || 'Sem descricao.'}</p>

            {ad.image ? (
              <img
                alt={ad.title}
                className="mt-3 h-28 w-full rounded-lg border border-red-100 object-cover"
                onError={(event) => {
                  event.currentTarget.style.display = 'none'
                }}
                src={resolveImageUrl(ad.image)}
              />
            ) : null}

            <div className="mt-3 flex flex-wrap items-center gap-2 text-xs">
              <Badge variant="blue">{adTypeLabel[ad.ad_type] || ad.ad_type}</Badge>
              <Badge variant="gray">Impressoes: {ad.impressions}</Badge>
              <Badge variant="gray">Cliques: {ad.clicks}</Badge>
            </div>

            <p className="mt-3 text-xs text-gray-500">
              {new Date(ad.starts_at).toLocaleDateString('pt-BR')} ate {new Date(ad.ends_at).toLocaleDateString('pt-BR')}
            </p>

            <div className="mt-4 flex gap-2">
              <button
                className={`rounded-lg px-3 py-1.5 text-xs font-bold text-white ${
                  ad.is_active ? 'bg-red-600 hover:bg-red-700' : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
                onClick={() => updateMutation.mutate({ id: ad.id, payload: { is_active: !ad.is_active } })}
                type="button"
              >
                {ad.is_active ? 'Desativar' : 'Ativar'}
              </button>
            </div>
          </article>
        ))}
      </div>

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

      {open ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 px-4">
          <div className="w-full max-w-xl rounded-2xl border border-red-100 bg-white p-5 shadow-xl">
            <h3 className="text-lg font-bold text-gray-900">Novo anuncio da plataforma</h3>
            <form className="mt-4 space-y-3" onSubmit={onSubmit}>
              <input
                className="w-full rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                onChange={(event) => setForm((state) => ({ ...state, title: event.target.value }))}
                placeholder="Titulo"
                required
                value={form.title}
              />
              <textarea
                className="w-full rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                onChange={(event) => setForm((state) => ({ ...state, description: event.target.value }))}
                placeholder="Descricao"
                rows={3}
                value={form.description}
              />
              <input
                className="w-full rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                onChange={(event) => setForm((state) => ({ ...state, image: event.target.value }))}
                placeholder="URL da imagem"
                required
                type="url"
                value={form.image}
              />
              <select
                className="w-full rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                onChange={(event) => setForm((state) => ({ ...state, ad_type: event.target.value }))}
                value={form.ad_type}
              >
                <option value="banner">Banner</option>
                <option value="featured_product">Produto em destaque</option>
                <option value="sponsored_store">Loja patrocinada</option>
              </select>

              <div className="grid gap-3 md:grid-cols-2">
                <input
                  className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                  onChange={(event) => setForm((state) => ({ ...state, starts_at: event.target.value }))}
                  required
                  type="datetime-local"
                  value={form.starts_at}
                />
                <input
                  className="rounded-xl border border-red-100 px-3 py-2.5 text-sm outline-none focus:border-primary"
                  onChange={(event) => setForm((state) => ({ ...state, ends_at: event.target.value }))}
                  required
                  type="datetime-local"
                  value={form.ends_at}
                />
              </div>

              <div className="mt-4 flex items-center justify-end gap-2">
                <button
                  className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50"
                  onClick={() => setOpen(false)}
                  type="button"
                >
                  Cancelar
                </button>
                <button
                  className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
                  disabled={createMutation.isPending}
                  type="submit"
                >
                  <Megaphone className="h-4 w-4" />
                  {createMutation.isPending ? 'Salvando...' : 'Criar anuncio'}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </div>
  )
}

export default AdsPage
