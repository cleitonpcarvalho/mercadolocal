import { MapPin } from "lucide-react";
import { Link } from "react-router-dom";

import { DEFAULT_IMAGE } from "../utils/helpers";

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

function StoreCard({ store }) {
  return (
    <Link
      className="block rounded-2xl border border-red-100 bg-white p-4 shadow-sm transition hover:-translate-y-1 hover:shadow-md"
      to={`/store/${store.id}`}
    >
      <div className="flex items-center gap-3">
        <img
          alt={store.name}
          className="h-16 w-16 rounded-xl object-cover"
          onError={(event) => {
            event.currentTarget.src = "/placeholder-image.svg";
          }}
          src={resolveImageUrl(store.logo)}
        />

        <div className="min-w-0">
          <h3 className="truncate text-base font-bold text-gray-900">{store.name}</h3>
          <p className="line-clamp-2 text-xs text-gray-500">{store.description}</p>
          <p className="mt-1 inline-flex items-center gap-1 text-xs font-medium text-primary">
            <MapPin className="h-3.5 w-3.5" />
            {store.city}
          </p>
        </div>
      </div>

      {store.categories?.length ? (
        <div className="mt-3 flex flex-wrap gap-1">
          {store.categories.slice(0, 3).map((category) => (
            <span
              className="rounded-full bg-red-50 px-2 py-1 text-[10px] font-semibold uppercase tracking-wide text-primary"
              key={category.id}
            >
              {category.name}
            </span>
          ))}
        </div>
      ) : null}
    </Link>
  );
}

export default StoreCard;
