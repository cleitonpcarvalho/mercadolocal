import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ShoppingCart, Store } from "lucide-react";
import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import ProductCard from "../../components/ProductCard";
import { useCartStore } from "../../context/CartStore";
import { getProductById, getProducts } from "../../services/productService";
import { extractListData, extractSingleData, formatCurrencyBRL, toTitle } from "../../utils/helpers";

function ProductDetailPage() {
  const navigate = useNavigate();
  const { id } = useParams();
  const addItem = useCartStore((state) => state.addItem);
  const [activeImage, setActiveImage] = useState(0);

  const productQuery = useQuery({
    queryKey: ["product-detail", id],
    queryFn: () => getProductById(id),
    enabled: Boolean(id),
  });

  const product = extractSingleData(productQuery.data);

  const relatedProductsQuery = useQuery({
    queryKey: ["related-products", product?.store?.id],
    queryFn: () => getProducts({ store: product.store.id }),
    enabled: Boolean(product?.store?.id),
  });

  const relatedProducts = useMemo(
    () => extractListData(relatedProductsQuery.data).filter((item) => item.id !== Number(id)).slice(0, 4),
    [relatedProductsQuery.data, id]
  );

  if (productQuery.isLoading) return <LoadingSpinner label="Carregando produto..." />;
  if (!product) {
    return <EmptyState description="Este item pode ter sido removido." title="Produto não encontrado" />;
  }

  const images = product.images?.length
    ? product.images
    : [{ id: "fallback", image: "/placeholder-image.svg" }];

  return (
    <div className="space-y-10">
      <button
        className="inline-flex items-center gap-1 text-sm font-semibold text-primary"
        onClick={() => navigate(-1)}
        type="button"
      >
        <ArrowLeft className="h-4 w-4" />
        Voltar
      </button>

      <section className="grid gap-6 rounded-3xl border border-red-100 bg-white p-5 shadow-sm lg:grid-cols-[1fr_1fr]">
        <div>
          <img
            alt={product.name}
            className="h-[360px] w-full rounded-2xl border border-red-100 object-cover"
            onError={(event) => {
              event.currentTarget.src = "/placeholder-image.svg";
            }}
            src={images[activeImage]?.image || "/placeholder-image.svg"}
          />
          <div className="mt-3 grid grid-cols-4 gap-2">
            {images.map((image, index) => (
              <button
                className={`overflow-hidden rounded-xl border ${
                  activeImage === index ? "border-primary" : "border-red-100"
                }`}
                key={image.id || index}
                onClick={() => setActiveImage(index)}
                type="button"
              >
                <img
                  alt={`${product.name} ${index + 1}`}
                  className="h-20 w-full object-cover"
                  onError={(event) => {
                    event.currentTarget.src = "/placeholder-image.svg";
                  }}
                  src={image.image}
                />
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-5">
          <div>
            <h1 className="text-3xl font-extrabold text-gray-900">{product.name}</h1>
            <p className="mt-2 text-sm text-gray-600">{product.description}</p>
          </div>

          <span className="inline-flex rounded-full bg-red-100 px-3 py-1 text-xs font-bold uppercase text-primary">
            {toTitle(product.condition)}
          </span>

          <p className="text-4xl font-black text-gray-900">{formatCurrencyBRL(product.price)}</p>

          <button
            className="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-3 font-semibold text-white hover:bg-red-700"
            onClick={() => addItem(product)}
            type="button"
          >
            <ShoppingCart className="h-5 w-5" />
            Adicionar ao carrinho
          </button>

          <div className="rounded-2xl border border-red-100 bg-red-50/40 p-4">
            <p className="text-xs font-semibold uppercase text-gray-500">Loja</p>
            <p className="mt-1 text-base font-bold text-gray-900">{product.store?.name}</p>
            <p className="text-sm text-gray-600">{product.store?.address}</p>
            <Link
              className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-primary"
              to={`/store/${product.store?.id}`}
            >
              <Store className="h-4 w-4" />
              Ver loja
            </Link>
          </div>
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-2xl font-bold">Produtos relacionados</h2>
        {relatedProductsQuery.isLoading ? <LoadingSpinner /> : null}
        {relatedProducts.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {relatedProducts.map((item) => (
              <ProductCard key={item.id} product={item} />
            ))}
          </div>
        ) : (
          !relatedProductsQuery.isLoading &&
          <EmptyState description="A loja ainda não possui mais itens disponíveis." title="Sem relacionados" />
        )}
      </section>
    </div>
  );
}

export default ProductDetailPage;
