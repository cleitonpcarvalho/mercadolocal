export const BRAND_RED = "#E8000D";

export const DEFAULT_IMAGE =
  "https://placehold.co/600x400/FFFFFF/E8000D?text=Mercado+Local";

export const extractListData = (payload) => {
  if (!payload) return [];
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.data?.results)) return payload.data.results;
  if (Array.isArray(payload.results)) return payload.results;
  return [];
};

export const extractSingleData = (payload) => payload?.data || payload || null;

export const formatCurrencyBRL = (value) =>
  new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(Number(value || 0));

export const toTitle = (value = "") =>
  value
    .toString()
    .replaceAll("_", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

export const getErrorMessage = (error) => {
  if (!error) return "Ocorreu um erro inesperado.";

  const responseData = error?.response?.data;
  if (responseData?.message) return responseData.message;

  if (responseData?.data && typeof responseData.data === "object") {
    const firstKey = Object.keys(responseData.data)[0];
    const firstValue = responseData.data[firstKey];
    if (Array.isArray(firstValue)) return firstValue[0];
    if (typeof firstValue === "string") return firstValue;
  }

  return error.message || "Ocorreu um erro inesperado.";
};

export const statusColorMap = {
  pending: "bg-amber-100 text-amber-700",
  confirmed: "bg-blue-100 text-blue-700",
  preparing: "bg-indigo-100 text-indigo-700",
  ready: "bg-purple-100 text-purple-700",
  in_delivery: "bg-cyan-100 text-cyan-700",
  delivered: "bg-emerald-100 text-emerald-700",
  cancelled: "bg-red-100 text-red-700",
  waiting: "bg-slate-100 text-slate-700",
  accepted: "bg-blue-100 text-blue-700",
  picked_up: "bg-orange-100 text-orange-700",
  failed: "bg-red-100 text-red-700",
};
