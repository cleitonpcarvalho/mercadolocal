import { useMutation, useQuery } from "@tanstack/react-query";
import { Save } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import toast from "react-hot-toast";

import LoadingSpinner from "../../components/LoadingSpinner";
import MapPicker from "../../components/MapPicker";
import { createStore, getMyStore, getStoreCategories, updateStore } from "../../services/storeService";
import { extractListData, extractSingleData, getErrorMessage } from "../../utils/helpers";

function MyStorePage() {
  const [form, setForm] = useState({
    name: "",
    description: "",
    phone: "",
    address: "",
    city: "",
    state: "",
    latitude: "",
    longitude: "",
    categories: [],
    logo: null,
  });

  const myStoreQuery = useQuery({
    queryKey: ["my-store"],
    queryFn: getMyStore,
    retry: false,
  });

  const categoriesQuery = useQuery({
    queryKey: ["store-categories"],
    queryFn: getStoreCategories,
  });

  const myStore = extractSingleData(myStoreQuery.data);
  const categories = extractListData(categoriesQuery.data);

  useEffect(() => {
    if (!myStore) return;

    // eslint-disable-next-line react-hooks/set-state-in-effect
    setForm((state) => ({
      ...state,
      name: myStore.name || "",
      description: myStore.description || "",
      phone: myStore.phone || "",
      address: myStore.address || "",
      city: myStore.city || "",
      state: myStore.state || "",
      latitude: myStore.latitude || "",
      longitude: myStore.longitude || "",
      categories: myStore.categories?.map((item) => item.id) || [],
      logo: null,
    }));
  }, [myStore]);

  const saveMutation = useMutation({
    mutationFn: async (payload) => {
      if (myStore?.id) {
        return updateStore(myStore.id, payload);
      }
      return createStore(payload);
    },
    onSuccess: (payload) => {
      toast.success(payload?.message || "Loja salva com sucesso.");
      myStoreQuery.refetch();
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const position = useMemo(() => {
    if (!form.latitude || !form.longitude) return null;
    return { lat: Number(form.latitude), lng: Number(form.longitude) };
  }, [form.latitude, form.longitude]);

  const onSubmit = (event) => {
    event.preventDefault();

    const payload = new FormData();
    payload.append("name", form.name);
    payload.append("description", form.description);
    payload.append("phone", form.phone);
    payload.append("address", form.address);
    payload.append("city", form.city);
    payload.append("state", form.state);
    payload.append("latitude", form.latitude);
    payload.append("longitude", form.longitude);
    payload.append("is_active", "true");

    form.categories.forEach((categoryId) => payload.append("categories", categoryId));

    if (form.logo) payload.append("logo", form.logo);

    saveMutation.mutate(payload);
  };

  if (myStoreQuery.isLoading || categoriesQuery.isLoading) {
    return <LoadingSpinner label="Carregando dados da loja..." />;
  }

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-extrabold">Minha loja</h1>

      <form className="grid gap-5 rounded-2xl border border-red-100 bg-white p-5 shadow-sm" onSubmit={onSubmit}>
        <div className="grid gap-4 md:grid-cols-2">
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, name: event.target.value }))}
            placeholder="Nome da loja"
            required
            value={form.name}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, phone: event.target.value }))}
            placeholder="Telefone"
            required
            value={form.phone}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 md:col-span-2"
            onChange={(event) => setForm((state) => ({ ...state, address: event.target.value }))}
            placeholder="Endereço"
            required
            value={form.address}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, city: event.target.value }))}
            placeholder="Cidade"
            required
            value={form.city}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, state: event.target.value }))}
            placeholder="Estado"
            required
            value={form.state}
          />
        </div>

        <textarea
          className="rounded-xl border border-red-100 px-4 py-3"
          onChange={(event) => setForm((state) => ({ ...state, description: event.target.value }))}
          placeholder="Descrição"
          rows={4}
          value={form.description}
        />

        <div className="space-y-2">
          <label className="text-sm font-semibold">Categorias</label>
          <select
            className="min-h-[120px] w-full rounded-xl border border-red-100 p-3"
            multiple
            onChange={(event) => {
              const selected = Array.from(event.target.selectedOptions).map((option) => Number(option.value));
              setForm((state) => ({ ...state, categories: selected }));
            }}
            value={form.categories.map(String)}
          >
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-semibold">Logo</label>
          <input
            accept="image/*"
            className="w-full rounded-xl border border-red-100 px-3 py-2"
            onChange={(event) =>
              setForm((state) => ({ ...state, logo: event.target.files?.[0] || null }))
            }
            type="file"
          />
        </div>

        <div className="space-y-2">
          <p className="text-sm font-semibold">Localização da loja</p>
          <MapPicker
            onChange={(location) => {
              setForm((state) => ({
                ...state,
                latitude: location.lat.toString(),
                longitude: location.lng.toString(),
              }));
            }}
            value={position}
          />
          <div className="grid gap-3 md:grid-cols-2">
            <input
              className="rounded-xl border border-red-100 px-4 py-2"
              onChange={(event) => setForm((state) => ({ ...state, latitude: event.target.value }))}
              placeholder="Latitude"
              required
              value={form.latitude}
            />
            <input
              className="rounded-xl border border-red-100 px-4 py-2"
              onChange={(event) => setForm((state) => ({ ...state, longitude: event.target.value }))}
              placeholder="Longitude"
              required
              value={form.longitude}
            />
          </div>
        </div>

        <button
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700"
          disabled={saveMutation.isPending}
          type="submit"
        >
          <Save className="h-4 w-4" />
          {saveMutation.isPending ? "Salvando..." : "Salvar loja"}
        </button>
      </form>
    </div>
  );
}

export default MyStorePage;
