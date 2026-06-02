import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, MapPin, Search } from "lucide-react";
import { useMemo, useState } from "react";
import { MapContainer, Marker, TileLayer } from "react-leaflet";
import { useNavigate, useParams } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import ProductCard from "../../components/ProductCard";
import { getProducts } from "../../services/productService";
import { getStoreById } from "../../services/storeService";
import { extractListData, extractSingleData } from "../../utils/helpers";

function StorePage() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [search, setSearch] = useState("");

  const storeQuery = useQuery({
    queryKey: ["store", id],
    queryFn: () => getStoreById(id),
    enabled: Boolean(id),
  });

  const store = extractSingleData(storeQuery.data);

  const productsQuery = useQuery({
    queryKey: ["store-products", id],
    queryFn: () => getProducts({ store: id }),
    enabled: Boolean(id),
  });

  const products = useMemo(() => {
    const list = extractListData(productsQuery.data);
    if (!search.trim()) return list;
    return list.filter((product) =>
      product.name.toLowerCase().includes(search.trim().toLowerCase())
    );
  }, [productsQuery.data, search]);

  if (storeQuery.isLoading) return <LoadingSpinner label="Carregando loja..." />;
  if (!store) return <EmptyState description="Esta loja não está disponível." title="Loja não encontrada" />;

  return (
    <div className="space-y-6">
      <button
        className="inline-flex items-center gap-1 text-sm font-semibold text-primary"
        onClick={() => navigate(-1)}
        type="button"
      >
        <ArrowLeft className="h-4 w-4" />
        Voltar
      </button>

      <section className="rounded-3xl border border-red-100 bg-white p-5 shadow-sm md:p-8">
        <div className="flex flex-wrap items-center gap-4">
          <img
            alt={store.name}
            className="h-20 w-20 rounded-2xl object-cover"
            onError={(event) => {
              event.currentTarget.src = "/placeholder-image.svg";
            }}
            src={store.logo || "/placeholder-image.svg"}
          />
          <div>
            <h1 className="text-2xl font-extrabold">{store.name}</h1>
            <p className="text-sm text-gray-600">{store.description}</p>
            <p className="mt-2 inline-flex items-center gap-1 text-sm font-medium text-primary">
              <MapPin className="h-4 w-4" />
              {store.address}
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              {store.categories?.map((category) => (
                <span
                  className="rounded-full bg-red-100 px-3 py-1 text-xs font-semibold uppercase text-primary"
                  key={category.id}
                >
                  {category.name}
                </span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <div className="space-y-4">
          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              className="w-full rounded-xl border border-red-100 bg-white py-3 pl-9 pr-4 outline-none focus:border-primary"
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Buscar produto na loja"
              value={search}
            />
          </div>

          {productsQuery.isLoading ? <LoadingSpinner /> : null}
          {products.length === 0 && !productsQuery.isLoading ? (
            <EmptyState description="Esta loja ainda não publicou produtos." title="Sem produtos" />
          ) : null}

          {products.length > 0 ? (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {products.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          ) : null}
        </div>

        <div className="h-fit rounded-2xl border border-red-100 bg-white p-3 shadow-sm">
          <p className="mb-2 text-sm font-semibold text-gray-500">Localização da loja</p>
          <div className="overflow-hidden rounded-xl">
            <MapContainer
              center={[Number(store.latitude), Number(store.longitude)]}
              scrollWheelZoom
              style={{ height: "320px", width: "100%" }}
              zoom={14}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <Marker position={[Number(store.latitude), Number(store.longitude)]} />
            </MapContainer>
          </div>
        </div>
      </section>
    </div>
  );
}

export default StorePage;
