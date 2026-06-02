import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, SlidersHorizontal } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import ProductCard from "../../components/ProductCard";
import { getCategoryTree, getProducts } from "../../services/productService";
import { extractListData } from "../../utils/helpers";

function SearchResultsPage() {
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();

  const [condition, setCondition] = useState(params.get("condition") || "");
  const [category, setCategory] = useState(params.get("category") || "");
  const [minPrice, setMinPrice] = useState(params.get("min_price") || "");
  const [maxPrice, setMaxPrice] = useState(params.get("max_price") || "");
  const [sortBy, setSortBy] = useState("relevance");

  const queryParams = {
    search: params.get("q") || "",
    category,
    condition,
    min_price: minPrice,
    max_price: maxPrice,
  };

  const productsQuery = useQuery({
    queryKey: ["search-products", queryParams],
    queryFn: () => getProducts(queryParams),
  });

  const categoriesQuery = useQuery({
    queryKey: ["product-categories-tree"],
    queryFn: getCategoryTree,
  });

  const categories = useMemo(() => extractListData(categoriesQuery.data), [categoriesQuery.data]);
  const products = useMemo(() => {
    const list = extractListData(productsQuery.data);
    if (sortBy === "lowest_price") return [...list].sort((a, b) => Number(a.price) - Number(b.price));
    if (sortBy === "highest_price") return [...list].sort((a, b) => Number(b.price) - Number(a.price));
    return list;
  }, [productsQuery.data, sortBy]);

  const applyFilters = () => {
    const next = new URLSearchParams(params);
    if (category) next.set("category", category);
    else next.delete("category");

    if (condition) next.set("condition", condition);
    else next.delete("condition");

    if (minPrice) next.set("min_price", minPrice);
    else next.delete("min_price");

    if (maxPrice) next.set("max_price", maxPrice);
    else next.delete("max_price");

    setParams(next);
  };

  return (
    <div className="space-y-4">
      <button
        className="inline-flex items-center gap-1 text-sm font-semibold text-primary"
        onClick={() => navigate(-1)}
        type="button"
      >
        <ArrowLeft className="h-4 w-4" />
        Voltar
      </button>

      <div className="grid gap-6 lg:grid-cols-[280px_1fr]">
      <aside className="h-fit space-y-4 rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
        <div className="flex items-center gap-2 text-gray-800">
          <SlidersHorizontal className="h-4 w-4" />
          <h2 className="text-sm font-bold uppercase">Filtros</h2>
        </div>

        <div className="space-y-2">
          <label className="text-xs font-semibold uppercase text-gray-500">Categoria</label>
          <select
            className="w-full rounded-xl border border-red-100 px-3 py-2 text-sm"
            onChange={(event) => setCategory(event.target.value)}
            value={category}
          >
            <option value="">Todas</option>
            {categories.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </div>

        <div className="space-y-2">
          <label className="text-xs font-semibold uppercase text-gray-500">Condição</label>
          <select
            className="w-full rounded-xl border border-red-100 px-3 py-2 text-sm"
            onChange={(event) => setCondition(event.target.value)}
            value={condition}
          >
            <option value="">Todas</option>
            <option value="new">Novo</option>
            <option value="used">Usado</option>
          </select>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <input
            className="rounded-xl border border-red-100 px-3 py-2 text-sm"
            min="0"
            onChange={(event) => setMinPrice(event.target.value)}
            placeholder="Preço min"
            type="number"
            value={minPrice}
          />
          <input
            className="rounded-xl border border-red-100 px-3 py-2 text-sm"
            min="0"
            onChange={(event) => setMaxPrice(event.target.value)}
            placeholder="Preço max"
            type="number"
            value={maxPrice}
          />
        </div>

        <button
          className="w-full rounded-xl bg-primary px-3 py-2 text-sm font-semibold text-white hover:bg-red-700"
          onClick={applyFilters}
          type="button"
        >
          Aplicar filtros
        </button>
      </aside>

      <section>
        <div className="mb-4 flex items-center justify-between rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
          <p className="text-sm text-gray-500">Resultados para: {params.get("q") || "todos os produtos"}</p>

          <select
            className="rounded-lg border border-red-100 px-3 py-2 text-sm"
            onChange={(event) => setSortBy(event.target.value)}
            value={sortBy}
          >
            <option value="relevance">Relevância</option>
            <option value="lowest_price">Menor preço</option>
            <option value="highest_price">Maior preço</option>
          </select>
        </div>

        {productsQuery.isLoading ? <LoadingSpinner /> : null}
        {products.length === 0 && !productsQuery.isLoading ? (
          <EmptyState description="Tente ajustar os filtros para encontrar mais itens." title="Nenhum produto encontrado" />
        ) : null}

        {products.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {products.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : null}
      </section>
      </div>
    </div>
  );
}

export default SearchResultsPage;
