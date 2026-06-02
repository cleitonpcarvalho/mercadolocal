import { useMutation, useQuery } from "@tanstack/react-query";
import {
  Car,
  Dumbbell,
  Home,
  NotebookPen,
  PawPrint,
  Shirt,
  Smartphone,
  Sparkles,
  ToyBrick,
  Trophy,
} from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import ProductCard from "../../components/ProductCard";
import StoreCard from "../../components/StoreCard";
import { getActiveAds, registerAdClick } from "../../services/adService";
import { getProducts } from "../../services/productService";
import { getStores } from "../../services/storeService";
import { extractListData } from "../../utils/helpers";

const featuredCategories = [
  { label: "Moda e Vestuário", icon: Shirt },
  { label: "Eletrônicos", icon: Smartphone },
  { label: "Beleza e Perfumaria", icon: Sparkles },
  { label: "Casa e Utilidades", icon: Home },
  { label: "Brinquedos", icon: ToyBrick },
  { label: "Peças Automotivas", icon: Car },
  { label: "Suplementos", icon: Dumbbell },
  { label: "Pet Shop", icon: PawPrint },
  { label: "Esporte e Lazer", icon: Trophy },
  { label: "Papelaria", icon: NotebookPen },
];

const SUPABASE_URL =
  import.meta.env.REACT_APP_SUPABASE_URL || import.meta.env.VITE_SUPABASE_URL || "";
const SUPABASE_BUCKET =
  import.meta.env.REACT_APP_SUPABASE_STORAGE_BUCKET ||
  import.meta.env.VITE_SUPABASE_STORAGE_BUCKET ||
  "mercadolocal";

const resolveImageUrl = (value, fallback = "/placeholder-image.svg") => {
  const rawValue = (value || "").toString().trim();
  if (!rawValue) return fallback;
  if (rawValue.startsWith("http")) return rawValue;
  if (!SUPABASE_URL) return rawValue.startsWith("/") ? rawValue : `/${rawValue}`;

  const normalizedPath = rawValue.replace(/^\/+/, "");
  return `${SUPABASE_URL.replace(/\/$/, "")}/storage/v1/object/public/${SUPABASE_BUCKET}/${normalizedPath}`;
};

function HomePage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");

  const featuredProductsQuery = useQuery({
    queryKey: ["featured-products"],
    queryFn: () => getProducts({ is_featured: true }),
  });

  const activeBannerAdsQuery = useQuery({
    queryKey: ["active-banner-ads"],
    queryFn: () => getActiveAds({ ad_type: "banner" }),
  });

  const storesQuery = useQuery({
    queryKey: ["stores-nearby"],
    queryFn: () => getStores(),
  });

  const registerClickMutation = useMutation({
    mutationFn: registerAdClick,
  });

  const featuredProducts = useMemo(
    () => extractListData(featuredProductsQuery.data).slice(0, 8),
    [featuredProductsQuery.data]
  );

  const ads = useMemo(() => extractListData(activeBannerAdsQuery.data), [activeBannerAdsQuery.data]);
  const stores = useMemo(() => extractListData(storesQuery.data).slice(0, 6), [storesQuery.data]);

  const onSearch = (event) => {
    event.preventDefault();
    navigate(`/search?q=${encodeURIComponent(search)}`);
  };

  return (
    <div className="space-y-10">
      <section className="overflow-hidden rounded-3xl border border-red-100 bg-white p-6 shadow-sm md:p-10">
        <div className="grid items-center gap-6 md:grid-cols-2">
          <div>
            <p className="inline-flex rounded-full bg-red-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-primary">
              Mercado Local
            </p>
            <h1 className="mt-4 text-3xl font-extrabold leading-tight md:text-5xl">
              O shopping da sua cidade, na palma da mão
            </h1>
            <p className="mt-3 text-gray-600">
              Encontre produtos de lojas locais, compre online e receba em minutos.
            </p>

            <form className="mt-6 flex gap-2" onSubmit={onSearch}>
              <input
                className="flex-1 rounded-xl border border-red-100 bg-red-50/40 px-4 py-3 outline-none focus:border-primary"
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Buscar por produto"
                value={search}
              />
              <button
                className="rounded-xl bg-primary px-5 py-3 font-semibold text-white hover:bg-red-700"
                type="submit"
              >
                Buscar
              </button>
            </form>
          </div>

          <div className="grid grid-cols-2 gap-3 rounded-2xl bg-red-50 p-4">
            {featuredCategories.map((category) => (
              <button
                className="flex items-center gap-2 rounded-xl bg-white px-3 py-3 text-sm font-semibold text-gray-700 transition hover:border-primary hover:text-primary"
                key={category.label}
                onClick={() => navigate(`/search?category_label=${encodeURIComponent(category.label)}`)}
                type="button"
              >
                <category.icon className="h-4 w-4 text-primary" />
                {category.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Banners ativos</h2>
        </div>
        {activeBannerAdsQuery.isLoading ? <LoadingSpinner /> : null}
        {ads.length === 0 && !activeBannerAdsQuery.isLoading ? (
          <EmptyState description="Sem campanhas no momento." title="Nenhum banner ativo" />
        ) : null}
        {ads.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2">
            {ads.map((ad) => (
              <button
                className="overflow-hidden rounded-2xl border border-red-100 bg-white text-left shadow-sm"
                key={ad.id}
                onClick={() => {
                  registerClickMutation.mutate(ad.id);
                  if (ad.product) navigate(`/product/${ad.product}`);
                }}
                type="button"
              >
                <img
                  alt={ad.title}
                  className="h-48 w-full object-cover"
                  onError={(event) => {
                    event.currentTarget.src = "/placeholder-image.svg";
                  }}
                  src={resolveImageUrl(ad.image)}
                />
                <div className="p-4">
                  <h3 className="font-bold text-gray-900">{ad.title}</h3>
                  <p className="text-sm text-gray-500">{ad.description}</p>
                </div>
              </button>
            ))}
          </div>
        ) : null}
      </section>

      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Produtos em destaque</h2>
          <button className="text-sm font-semibold text-primary" onClick={() => navigate("/search")} type="button">
            Ver todos
          </button>
        </div>

        {featuredProductsQuery.isLoading ? <LoadingSpinner /> : null}
        {featuredProducts.length === 0 && !featuredProductsQuery.isLoading ? (
          <EmptyState description="Novidades chegando em breve." title="Nenhum produto em destaque" />
        ) : null}

        {featuredProducts.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {featuredProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : null}
      </section>

      <section className="space-y-4 pb-8">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Lojas perto de você</h2>
          <button className="text-sm font-semibold text-primary" onClick={() => navigate("/search")} type="button">
            Explorar
          </button>
        </div>

        {storesQuery.isLoading ? <LoadingSpinner /> : null}
        {stores.length === 0 && !storesQuery.isLoading ? (
          <EmptyState description="Tente novamente em instantes." title="Nenhuma loja encontrada" />
        ) : null}

        {stores.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {stores.map((store) => (
              <StoreCard key={store.id} store={store} />
            ))}
          </div>
        ) : null}
      </section>
    </div>
  );
}

export default HomePage;
