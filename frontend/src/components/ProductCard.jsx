import { PlusCircle } from "lucide-react";
import { Link } from "react-router-dom";

import { useCartStore } from "../context/CartStore";
import { DEFAULT_IMAGE, formatCurrencyBRL, toTitle } from "../utils/helpers";

const SUPABASE_URL =
  import.meta.env.REACT_APP_SUPABASE_URL || import.meta.env.VITE_SUPABASE_URL || "";
const SUPABASE_BUCKET =
  import.meta.env.REACT_APP_SUPABASE_STORAGE_BUCKET ||
  import.meta.env.VITE_SUPABASE_STORAGE_BUCKET ||
  "mercadolocal";

const resolveImageUrl = (value) => {
  const rawValue = (value || "").toString().trim();
  if (!rawValue) return DEFAULT_IMAGE;
  if (rawValue.startsWith("http")) return rawValue;
  if (!SUPABASE_URL) return rawValue.startsWith("/") ? rawValue : `/${rawValue}`;

  const normalizedPath = rawValue.replace(/^\/+/, "");
  return `${SUPABASE_URL.replace(/\/$/, "")}/storage/v1/object/public/${SUPABASE_BUCKET}/${normalizedPath}`;
};

function ProductCard({ product }) {
  const addItem = useCartStore((state) => state.addItem);
  const firstRelatedImage = product.images?.[0]?.image || product.first_image;

  const handleAddToCart = () => {
    addItem(product);
  };

  return (
    <article className="overflow-hidden rounded-2xl border border-red-100 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-md">
      <Link to={`/product/${product.id}`}>
        <img
          alt={product.name}
          className="h-44 w-full object-cover"
          onError={(event) => {
            event.currentTarget.src = "/placeholder-image.svg";
          }}
          src={resolveImageUrl(firstRelatedImage)}
        />
      </Link>

      <div className="space-y-3 p-4">
        <div className="flex items-start justify-between gap-2">
          <h3 className="line-clamp-2 text-sm font-bold text-gray-900">{product.name}</h3>
          <span className="rounded-full bg-red-100 px-2 py-1 text-[10px] font-bold uppercase text-primary">
            {toTitle(product.condition)}
          </span>
        </div>

        <p className="text-xs text-gray-500">{product.store?.name || "Loja parceira"}</p>

        <div className="flex items-center justify-between">
          <p className="text-lg font-extrabold text-gray-900">{formatCurrencyBRL(product.price)}</p>
          <button
            className="inline-flex items-center gap-1 rounded-lg bg-primary px-3 py-2 text-xs font-semibold text-white hover:bg-red-700"
            onClick={handleAddToCart}
            type="button"
          >
            <PlusCircle className="h-4 w-4" />
            Adicionar
          </button>
        </div>
      </div>
    </article>
  );
}

export default ProductCard;
