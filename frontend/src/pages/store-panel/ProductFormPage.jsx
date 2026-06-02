import { useMutation, useQuery } from "@tanstack/react-query";
import { Save } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import toast from "react-hot-toast";
import { useNavigate, useParams } from "react-router-dom";

import LoadingSpinner from "../../components/LoadingSpinner";
import { createProduct, getCategoryTree, getProductById, updateProduct } from "../../services/productService";
import { extractListData, extractSingleData, getErrorMessage } from "../../utils/helpers";

function ProductFormPage() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEdit = Boolean(id);

  const [form, setForm] = useState({
    name: "",
    description: "",
    price: "",
    stock: "",
    condition: "new",
    weight_kg: "",
    category: "",
    pickup_only: false,
    images: [],
    imagePreviews: [],
  });

  const categoriesQuery = useQuery({
    queryKey: ["categories-for-product-form"],
    queryFn: getCategoryTree,
  });

  const productQuery = useQuery({
    queryKey: ["product-to-edit", id],
    queryFn: () => getProductById(id),
    enabled: isEdit,
  });

  const categories = extractListData(categoriesQuery.data);
  const existingProduct = extractSingleData(productQuery.data);

  useEffect(() => {
    if (!existingProduct) return;

    // eslint-disable-next-line react-hooks/set-state-in-effect
    setForm((state) => ({
      ...state,
      name: existingProduct.name || "",
      description: existingProduct.description || "",
      price: existingProduct.price || "",
      stock: existingProduct.stock || "",
      condition: existingProduct.condition || "new",
      weight_kg: existingProduct.weight_kg || "",
      category: existingProduct.category?.id || "",
      pickup_only: Boolean(existingProduct.pickup_only),
      images: [],
      imagePreviews: existingProduct.images?.map((image) => image.image) || [],
    }));
  }, [existingProduct]);

  const saveMutation = useMutation({
    mutationFn: async (payload) => {
      if (isEdit) return updateProduct(id, payload);
      return createProduct(payload);
    },
    onSuccess: (payload) => {
      toast.success(payload?.message || "Produto salvo com sucesso.");
      navigate("/store-panel/products");
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const submit = (event) => {
    event.preventDefault();

    const payload = new FormData();
    payload.append("name", form.name);
    payload.append("description", form.description);
    payload.append("price", form.price);
    payload.append("stock", form.stock);
    payload.append("condition", form.condition);
    payload.append("weight_kg", form.weight_kg);
    payload.append("category", form.category);
    payload.append("pickup_only", form.pickup_only ? "true" : "false");

    form.images.forEach((file) => payload.append("images", file));

    saveMutation.mutate(payload);
  };

  const canRender = !categoriesQuery.isLoading && (!isEdit || !productQuery.isLoading);

  const previewImages = useMemo(() => form.imagePreviews || [], [form.imagePreviews]);

  if (!canRender) return <LoadingSpinner label="Carregando formulário..." />;

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-extrabold">{isEdit ? "Editar produto" : "Novo produto"}</h1>

      <form className="grid gap-4 rounded-2xl border border-red-100 bg-white p-5 shadow-sm" onSubmit={submit}>
        <input
          className="rounded-xl border border-red-100 px-4 py-3"
          onChange={(event) => setForm((state) => ({ ...state, name: event.target.value }))}
          placeholder="Nome"
          required
          value={form.name}
        />

        <textarea
          className="rounded-xl border border-red-100 px-4 py-3"
          onChange={(event) => setForm((state) => ({ ...state, description: event.target.value }))}
          placeholder="Descrição"
          rows={4}
          value={form.description}
        />

        <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            min="0"
            onChange={(event) => setForm((state) => ({ ...state, price: event.target.value }))}
            placeholder="Preço"
            required
            step="0.01"
            type="number"
            value={form.price}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            min="0"
            onChange={(event) => setForm((state) => ({ ...state, stock: event.target.value }))}
            placeholder="Estoque"
            required
            type="number"
            value={form.stock}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3"
            min="0"
            onChange={(event) => setForm((state) => ({ ...state, weight_kg: event.target.value }))}
            placeholder="Peso (kg)"
            required
            step="0.001"
            type="number"
            value={form.weight_kg}
          />
          <select
            className="rounded-xl border border-red-100 px-4 py-3"
            onChange={(event) => setForm((state) => ({ ...state, condition: event.target.value }))}
            value={form.condition}
          >
            <option value="new">Novo</option>
            <option value="used">Usado</option>
          </select>
        </div>

        <select
          className="rounded-xl border border-red-100 px-4 py-3"
          onChange={(event) => setForm((state) => ({ ...state, category: event.target.value }))}
          required
          value={form.category}
        >
          <option value="">Selecione a categoria</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </select>

        <label className="inline-flex items-center gap-2 text-sm font-medium text-gray-700">
          <input
            checked={form.pickup_only}
            onChange={(event) => setForm((state) => ({ ...state, pickup_only: event.target.checked }))}
            type="checkbox"
          />
          Retirada no local apenas
        </label>

        <div>
          <label className="mb-2 block text-sm font-semibold">Imagens</label>
          <input
            accept="image/*"
            className="w-full rounded-xl border border-red-100 px-3 py-2"
            multiple
            onChange={(event) => {
              const files = Array.from(event.target.files || []);
              setForm((state) => ({
                ...state,
                images: files,
                imagePreviews: files.length ? files.map((file) => URL.createObjectURL(file)) : state.imagePreviews,
              }));
            }}
            type="file"
          />

          {previewImages.length > 0 ? (
            <div className="mt-3 grid grid-cols-2 gap-3 md:grid-cols-4">
              {previewImages.map((src, index) => (
                <img
                  alt={`Preview ${index + 1}`}
                  className="h-24 w-full rounded-xl border border-red-100 object-cover"
                  key={`${src}-${index}`}
                  onError={(event) => {
                    event.currentTarget.src = "/placeholder-image.svg";
                  }}
                  src={src}
                />
              ))}
            </div>
          ) : null}
        </div>

        <button
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700"
          disabled={saveMutation.isPending}
          type="submit"
        >
          <Save className="h-4 w-4" />
          {saveMutation.isPending ? "Salvando..." : "Salvar produto"}
        </button>
      </form>
    </div>
  );
}

export default ProductFormPage;
