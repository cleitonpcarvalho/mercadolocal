import { useMutation, useQuery } from "@tanstack/react-query";
import { PlusCircle, Search, SquarePen, ToggleLeft, ToggleRight } from "lucide-react";
import { useMemo, useState } from "react";
import toast from "react-hot-toast";
import { Link, useNavigate } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import { deleteProduct, getCategoryTree, getMyProducts, updateProduct } from "../../services/productService";
import { extractListData, formatCurrencyBRL, getErrorMessage, toTitle } from "../../utils/helpers";

function ProductsPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");

  const myProductsQuery = useQuery({
    queryKey: ["my-products"],
    queryFn: getMyProducts,
  });

  const categoriesQuery = useQuery({
    queryKey: ["category-tree-products-page"],
    queryFn: getCategoryTree,
  });

  const archiveMutation = useMutation({
    mutationFn: deleteProduct,
    onSuccess: (payload) => {
      toast.success(payload?.message || "Produto atualizado com sucesso");
      myProductsQuery.refetch();
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, payload }) => updateProduct(id, payload),
    onSuccess: () => {
      toast.success("Status atualizado.");
      myProductsQuery.refetch();
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const categories = extractListData(categoriesQuery.data);
  const products = useMemo(() => {
    const list = extractListData(myProductsQuery.data);

    return list.filter((product) => {
      const searchMatch = search.trim()
        ? product.name.toLowerCase().includes(search.trim().toLowerCase())
        : true;
      const categoryMatch = categoryFilter ? String(product.category?.id) === categoryFilter : true;

      return searchMatch && categoryMatch;
    });
  }, [myProductsQuery.data, search, categoryFilter]);

  if (myProductsQuery.isLoading) return <LoadingSpinner label="Carregando produtos..." />;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-extrabold">Produtos</h1>
        <button
          className="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
          onClick={() => navigate("/store-panel/products/new")}
          type="button"
        >
          <PlusCircle className="h-4 w-4" />
          Novo produto
        </button>
      </div>

      <div className="grid gap-3 rounded-2xl border border-red-100 bg-white p-4 shadow-sm md:grid-cols-[1fr_220px]">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            className="w-full rounded-xl border border-red-100 py-2 pl-9 pr-3"
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Buscar por nome"
            value={search}
          />
        </div>

        <select
          className="rounded-xl border border-red-100 px-3 py-2"
          onChange={(event) => setCategoryFilter(event.target.value)}
          value={categoryFilter}
        >
          <option value="">Todas categorias</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </select>
      </div>

      {products.length === 0 ? (
        <EmptyState description="Cadastre seu primeiro produto." title="Nenhum produto encontrado" />
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-red-100 bg-white shadow-sm">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="border-b border-red-100 text-left text-gray-500">
                <th className="px-4 py-3">Produto</th>
                <th className="px-4 py-3">Preço</th>
                <th className="px-4 py-3">Estoque</th>
                <th className="px-4 py-3">Condição</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Ações</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr className="border-b border-red-50" key={product.id}>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <img
                        alt={product.name}
                        className="h-12 w-12 rounded-lg object-cover"
                        onError={(event) => {
                          event.currentTarget.src = "/placeholder-image.svg";
                        }}
                        src={product.images?.[0]?.image || "/placeholder-image.svg"}
                      />
                      <div>
                        <p className="font-semibold text-gray-900">{product.name}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 font-semibold">{formatCurrencyBRL(product.price)}</td>
                  <td className="px-4 py-3">{product.stock}</td>
                  <td className="px-4 py-3">{toTitle(product.condition)}</td>
                  <td className="px-4 py-3">
                    <button
                      className="inline-flex items-center gap-1 text-xs font-semibold"
                      onClick={() =>
                        toggleMutation.mutate({
                          id: product.id,
                          payload: { is_available: !product.is_available },
                        })
                      }
                      type="button"
                    >
                      {product.is_available ? (
                        <>
                          <ToggleRight className="h-5 w-5 text-emerald-600" /> Ativo
                        </>
                      ) : (
                        <>
                          <ToggleLeft className="h-5 w-5 text-gray-400" /> Inativo
                        </>
                      )}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="inline-flex items-center gap-2">
                      <Link
                        className="inline-flex items-center gap-1 rounded-lg border border-red-100 px-3 py-1.5 text-xs font-semibold hover:bg-red-50"
                        to={`/store-panel/products/${product.id}/edit`}
                      >
                        <SquarePen className="h-3.5 w-3.5" /> Editar
                      </Link>
                      <button
                        className="rounded-lg border border-red-100 px-3 py-1.5 text-xs font-semibold text-red-700 hover:bg-red-50"
                        onClick={() => archiveMutation.mutate(product.id)}
                        type="button"
                      >
                        Arquivar
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default ProductsPage;
