import { useMutation, useQuery } from "@tanstack/react-query";
import { Megaphone, PlusCircle } from "lucide-react";
import { useState } from "react";
import toast from "react-hot-toast";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import { createAd, getMyAds } from "../../services/adService";
import { extractListData, formatCurrencyBRL, getErrorMessage, toTitle } from "../../utils/helpers";

const AD_TYPE_LABELS = {
  banner: "Banner",
  featured_product: "Produto em destaque",
  sponsored_store: "Loja patrocinada",
};

function AdsPage() {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    title: "",
    description: "",
    image: null,
    ad_type: "banner",
    starts_at: "",
    ends_at: "",
    price_paid: "",
  });

  const adsQuery = useQuery({
    queryKey: ["my-ads"],
    queryFn: getMyAds,
  });

  const createMutation = useMutation({
    mutationFn: createAd,
    onSuccess: (payload) => {
      toast.success(payload?.message || "Anúncio criado com sucesso.");
      setShowForm(false);
      setForm({
        title: "",
        description: "",
        image: null,
        ad_type: "banner",
        starts_at: "",
        ends_at: "",
        price_paid: "",
      });
      adsQuery.refetch();
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const ads = extractListData(adsQuery.data);

  const submit = (event) => {
    event.preventDefault();

    const payload = new FormData();
    payload.append("title", form.title);
    payload.append("description", form.description);
    payload.append("ad_type", form.ad_type);
    payload.append("starts_at", form.starts_at);
    payload.append("ends_at", form.ends_at);
    payload.append("price_paid", form.price_paid);
    if (form.image) payload.append("image", form.image);

    createMutation.mutate(payload);
  };

  if (adsQuery.isLoading) return <LoadingSpinner label="Carregando anúncios..." />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-extrabold">Anúncios</h1>
        <button
          className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
          onClick={() => setShowForm((state) => !state)}
          type="button"
        >
          <PlusCircle className="h-4 w-4" />
          Novo anúncio
        </button>
      </div>

      {showForm ? (
        <form className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm" onSubmit={submit}>
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, title: event.target.value }))}
            placeholder="Título"
            required
            value={form.title}
          />
          <textarea
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, description: event.target.value }))}
            placeholder="Descrição"
            rows={3}
            value={form.description}
          />
          <div className="grid gap-3 md:grid-cols-3">
            <select
              className="rounded-xl border border-red-100 px-4 py-3"
              onChange={(event) => setForm((state) => ({ ...state, ad_type: event.target.value }))}
              value={form.ad_type}
            >
              <option value="banner">Banner</option>
              <option value="featured_product">Produto em destaque</option>
              <option value="sponsored_store">Loja patrocinada</option>
            </select>
            <input
              className="rounded-xl border border-red-100 px-4 py-3"
              min="0"
              onChange={(event) => setForm((state) => ({ ...state, price_paid: event.target.value }))}
              placeholder="Preço pago"
              required
              step="0.01"
              type="number"
              value={form.price_paid}
            />
            <input
              accept="image/*"
              className="rounded-xl border border-red-100 px-3 py-2"
              onChange={(event) =>
                setForm((state) => ({ ...state, image: event.target.files?.[0] || null }))
              }
              required
              type="file"
            />
          </div>
          <div className="grid gap-3 md:grid-cols-2">
            <input
              className="rounded-xl border border-red-100 px-4 py-3"
              onChange={(event) => setForm((state) => ({ ...state, starts_at: event.target.value }))}
              required
              type="datetime-local"
              value={form.starts_at}
            />
            <input
              className="rounded-xl border border-red-100 px-4 py-3"
              onChange={(event) => setForm((state) => ({ ...state, ends_at: event.target.value }))}
              required
              type="datetime-local"
              value={form.ends_at}
            />
          </div>

          <button
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700"
            disabled={createMutation.isPending}
            type="submit"
          >
            <Megaphone className="h-4 w-4" />
            {createMutation.isPending ? "Criando..." : "Criar anúncio"}
          </button>
        </form>
      ) : null}

      {ads.length === 0 ? (
        <EmptyState description="Anuncie sua loja para aumentar alcance local." title="Nenhum anúncio cadastrado" />
      ) : (
        <div className="space-y-3">
          {ads.map((ad) => (
            <article className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm" key={ad.id}>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-bold text-gray-900">{ad.title}</p>
                  <p className="text-sm text-gray-500">
                    {AD_TYPE_LABELS[ad.ad_type] || toTitle(ad.ad_type)}
                  </p>
                </div>
                <p className="text-base font-extrabold text-gray-900">{formatCurrencyBRL(ad.price_paid)}</p>
              </div>

              <div className="mt-3 grid gap-2 text-sm md:grid-cols-3">
                <p>Impressões: {ad.impressions}</p>
                <p>Cliques: {ad.clicks}</p>
                <p>Status: {ad.is_active ? "Ativo" : "Inativo"}</p>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}

export default AdsPage;
