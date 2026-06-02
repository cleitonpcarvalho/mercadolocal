import { useMutation } from "@tanstack/react-query";
import { ArrowLeft, Minus, Plus, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";
import toast from "react-hot-toast";
import { useNavigate } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import MapPicker from "../../components/MapPicker";
import { useAuth } from "../../context/AuthContext";
import { useCartStore } from "../../context/CartStore";
import {
  buildDeliveryAddress,
  fetchAddressByCep,
  formatCep,
  geocodeAddress,
  sanitizeCep,
} from "../../services/addressService";
import { createOrder } from "../../services/orderService";
import { formatCurrencyBRL, getErrorMessage } from "../../utils/helpers";

function CartPage() {
  const navigate = useNavigate();
  const { isAuthenticated, user } = useAuth();
  const {
    items,
    deliveryLocation,
    paymentMethod,
    updateQuantity,
    removeItem,
    clearCart,
    setDeliveryAddress,
    setDeliveryLocation,
    setPaymentMethod,
  } = useCartStore((state) => state);

  const [notes, setNotes] = useState("");
  const [showNotes, setShowNotes] = useState(false);
  const [postalCode, setPostalCode] = useState("");
  const [street, setStreet] = useState("");
  const [addressNumber, setAddressNumber] = useState("");
  const [addressComplement, setAddressComplement] = useState("");
  const [neighborhood, setNeighborhood] = useState("");
  const [city, setCity] = useState("");
  const [stateCode, setStateCode] = useState("");
  const [isCepLoading, setIsCepLoading] = useState(false);
  const [isGeocoding, setIsGeocoding] = useState(false);

  const subtotal = useMemo(
    () => items.reduce((acc, item) => acc + Number(item.price) * item.quantity, 0),
    [items]
  );
  const deliveryFee = items.length ? 5 : 0;
  const total = subtotal + deliveryFee;

  const normalizeCoordinate = (value) => {
    const numeric = Number(value);
    if (!Number.isFinite(numeric)) return null;
    return Number(numeric.toFixed(6));
  };

  const normalizeLocation = (location) => {
    if (!location) return null;

    const lat = normalizeCoordinate(location.lat);
    const lng = normalizeCoordinate(location.lng);
    if (lat == null || lng == null) return null;

    return { lat, lng };
  };

  const createOrderMutation = useMutation({
    mutationFn: createOrder,
    onSuccess: (payload) => {
      toast.success(payload?.message || "Pedido criado com sucesso!");
      const orderId = payload?.data?.id;
      clearCart();
      navigate(orderId ? `/orders/${orderId}` : "/orders");
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const buildCurrentAddress = (overrides = {}) =>
    buildDeliveryAddress({
      street: `${overrides.street ?? street}`.trim(),
      number: `${overrides.number ?? addressNumber}`.trim(),
      complement: `${overrides.complement ?? addressComplement}`.trim(),
      neighborhood: `${overrides.neighborhood ?? neighborhood}`.trim(),
      city: `${overrides.city ?? city}`.trim(),
      state: `${overrides.state ?? stateCode}`.trim().toUpperCase(),
      cep: sanitizeCep(`${overrides.cep ?? postalCode}`),
    });

  const syncDeliveryAddress = (overrides = {}) => {
    const composedAddress = buildCurrentAddress(overrides);
    setDeliveryAddress(composedAddress);
    return composedAddress;
  };

  const buildGeocodeQueries = (primaryAddress) => {
    const queries = [
      primaryAddress,
      buildCurrentAddress({ complement: "" }),
      [street, neighborhood, city, stateCode].filter(Boolean).join(", "),
      [street, city, stateCode].filter(Boolean).join(", "),
      [street, city].filter(Boolean).join(", "),
      [sanitizeCep(postalCode), city, stateCode].filter(Boolean).join(", "),
      sanitizeCep(postalCode),
    ]
      .map((value) => `${value || ""}`.trim())
      .filter((value) => value.length >= 6);

    return [...new Set(queries)];
  };

  const updateMapFromAddress = async (address, { withFeedback = false } = {}) => {
    const normalizedAddress = `${address || ""}`.trim();
    if (!normalizedAddress) return null;

    setIsGeocoding(true);
    try {
      const attempts = buildGeocodeQueries(normalizedAddress);

      for (const query of attempts) {
        const location = await geocodeAddress(query);
        if (!location) continue;

        const finalLocation = normalizeLocation(location);
        if (finalLocation == null) continue;

        setDeliveryLocation(finalLocation);
        if (withFeedback) {
          toast.success("Endereço localizado no mapa.");
        }
        return finalLocation;
      }

      if (withFeedback) {
        toast.error("Não foi possível localizar esse endereço no mapa.");
      }
      return null;
    } catch (error) {
      if (withFeedback) {
        toast.error(getErrorMessage(error));
      }
      return null;
    } finally {
      setIsGeocoding(false);
    }
  };

  const handleAddressFieldBlur = async () => {
    const composedAddress = buildCurrentAddress();
    if (!composedAddress.trim()) return;
    await updateMapFromAddress(composedAddress);
  };

  const handleCepLookup = async () => {
    const cleanCep = sanitizeCep(postalCode);
    if (cleanCep.length !== 8) {
      toast.error("Digite um CEP válido com 8 dígitos.");
      return;
    }

    setIsCepLoading(true);
    try {
      const data = await fetchAddressByCep(cleanCep);

      const nextComplement = addressComplement.trim() || `${data?.complement || ""}`.trim();

      setPostalCode(data.cep);
      setStreet(data.street);
      setNeighborhood(data.neighborhood);
      setCity(data.city);
      setStateCode(`${data.state || ""}`.toUpperCase());
      if (nextComplement) {
        setAddressComplement(nextComplement);
      }

      const composedAddress = syncDeliveryAddress({
        cep: data.cep,
        street: data.street,
        neighborhood: data.neighborhood,
        city: data.city,
        state: `${data.state || ""}`.toUpperCase(),
        complement: nextComplement,
      });

      const location = await updateMapFromAddress(composedAddress);
      toast.success(
        location
          ? "Endereço preenchido e localizado no mapa."
          : "Endereço preenchido pelo CEP. Ajuste o ponto no mapa se necessário."
      );
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      setIsCepLoading(false);
    }
  };

  const placeOrder = () => {
    if (!isAuthenticated) {
      toast.error("Você precisa entrar antes de finalizar a compra.");
      navigate("/login?next=/cart");
      return;
    }

    if (user?.role !== "customer") {
      toast.error("Somente clientes podem finalizar pedidos no web.");
      return;
    }

    if (!items.length) {
      toast.error("Seu carrinho está vazio.");
      return;
    }

    if (
      !sanitizeCep(postalCode) ||
      !street.trim() ||
      !addressNumber.trim() ||
      !neighborhood.trim() ||
      !city.trim() ||
      !stateCode.trim()
    ) {
      toast.error("Preencha CEP, rua, número, bairro, cidade e UF.");
      return;
    }

    const composedAddress = buildCurrentAddress();
    const finalLocation = normalizeLocation(deliveryLocation);
    if (!composedAddress || finalLocation == null) {
      toast.error("Informe endereço e ponto de entrega no mapa.");
      return;
    }

    const storeId = items[0]?.storeId;
    const hasMultipleStores = items.some((item) => item.storeId !== storeId);
    if (hasMultipleStores) {
      toast.error("No MVP, o pedido deve conter produtos de uma única loja.");
      return;
    }

    setDeliveryAddress(composedAddress);
    createOrderMutation.mutate({
      store: storeId,
      items: items.map((item) => ({ product: item.id, quantity: item.quantity })),
      delivery_address: composedAddress,
      delivery_latitude: finalLocation.lat,
      delivery_longitude: finalLocation.lng,
      payment_method: paymentMethod,
      notes,
    });
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

      <div className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
      <section className="space-y-4 rounded-3xl border border-red-100 bg-white p-5 shadow-sm">
        <h1 className="text-2xl font-extrabold">Carrinho</h1>

        {items.length === 0 ? (
          <EmptyState description="Adicione produtos para continuar." title="Seu carrinho está vazio" />
        ) : null}

        {items.map((item) => (
          <article
            className="flex items-center gap-3 rounded-2xl border border-red-100 bg-red-50/30 p-3"
            key={item.id}
          >
            <img
              alt={item.name}
              className="h-20 w-20 rounded-xl object-cover"
              onError={(event) => {
                event.currentTarget.src = "/placeholder-image.svg";
              }}
              src={item.image || "/placeholder-image.svg"}
            />
            <div className="min-w-0 flex-1">
              <p className="truncate font-bold text-gray-900">{item.name}</p>
              <p className="text-xs text-gray-500">{item.storeName}</p>
              <p className="text-sm font-semibold text-primary">{formatCurrencyBRL(item.price)}</p>
            </div>

            <div className="flex items-center gap-2">
              <button
                className="rounded-lg border border-red-200 p-1"
                onClick={() => updateQuantity(item.id, item.quantity - 1)}
                type="button"
              >
                <Minus className="h-4 w-4" />
              </button>
              <span className="w-6 text-center text-sm font-semibold">{item.quantity}</span>
              <button
                className="rounded-lg border border-red-200 p-1"
                onClick={() => updateQuantity(item.id, item.quantity + 1)}
                type="button"
              >
                <Plus className="h-4 w-4" />
              </button>
              <button
                className="rounded-lg border border-red-200 p-1 text-red-600"
                onClick={() => removeItem(item.id)}
                type="button"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </article>
        ))}
      </section>

      <aside className="space-y-4 rounded-3xl border border-red-100 bg-white p-5 shadow-sm">
        <h2 className="text-xl font-extrabold">Resumo do pedido</h2>

        <div className="space-y-2 rounded-2xl bg-red-50/40 p-4 text-sm">
          <div className="flex justify-between">
            <span>Subtotal</span>
            <strong>{formatCurrencyBRL(subtotal)}</strong>
          </div>
          <div className="flex justify-between">
            <span>Entrega</span>
            <strong>{formatCurrencyBRL(deliveryFee)}</strong>
          </div>
          <div className="flex justify-between border-t border-red-100 pt-2 text-base">
            <span>Total</span>
            <strong>{formatCurrencyBRL(total)}</strong>
          </div>
        </div>

        <input
          className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
          inputMode="numeric"
          maxLength={9}
          onChange={(event) => {
            const value = formatCep(event.target.value);
            setPostalCode(value);
            syncDeliveryAddress({ cep: value });
          }}
          placeholder="CEP"
          value={postalCode}
        />

        <button
          className="w-full rounded-xl border border-red-200 px-4 py-3 text-sm font-semibold text-primary hover:bg-red-50 disabled:opacity-60"
          disabled={isCepLoading}
          onClick={handleCepLookup}
          type="button"
        >
          {isCepLoading ? "Buscando CEP..." : "Buscar endereço pelo CEP"}
        </button>

        <div className="grid gap-3 sm:grid-cols-2">
          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary sm:col-span-2"
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value;
              setStreet(value);
              syncDeliveryAddress({ street: value });
            }}
            placeholder="Rua"
            value={street}
          />

          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value;
              setAddressNumber(value);
              syncDeliveryAddress({ number: value });
            }}
            placeholder="Numero"
            value={addressNumber}
          />

          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value;
              setAddressComplement(value);
              syncDeliveryAddress({ complement: value });
            }}
            placeholder="Complemento"
            value={addressComplement}
          />

          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary sm:col-span-2"
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value;
              setNeighborhood(value);
              syncDeliveryAddress({ neighborhood: value });
            }}
            placeholder="Bairro"
            value={neighborhood}
          />

          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value;
              setCity(value);
              syncDeliveryAddress({ city: value });
            }}
            placeholder="Cidade"
            value={city}
          />

          <input
            className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm uppercase outline-none focus:border-primary"
            maxLength={2}
            onBlur={handleAddressFieldBlur}
            onChange={(event) => {
              const value = event.target.value.toUpperCase().slice(0, 2);
              setStateCode(value);
              syncDeliveryAddress({ state: value });
            }}
            placeholder="UF"
            value={stateCode}
          />
        </div>

        <select
          className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
          onChange={(event) => setPaymentMethod(event.target.value)}
          value={paymentMethod}
        >
          <option value="pix">Pix</option>
          <option value="credit_card">Cartao de credito</option>
          <option value="debit_card">Cartao de debito</option>
        </select>

        {showNotes ? (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase text-gray-500">Instruções de entrega (opcional)</p>
              <button
                className="text-xs font-semibold text-gray-500 hover:text-primary"
                onClick={() => setShowNotes(false)}
                type="button"
              >
                Ocultar
              </button>
            </div>
            <textarea
              className="w-full rounded-xl border border-red-100 px-3 py-3 text-sm outline-none focus:border-primary"
              onChange={(event) => setNotes(event.target.value)}
              placeholder="Ex.: deixar na portaria, bloco ou referencia do local."
              rows={3}
              value={notes}
            />
          </div>
        ) : (
          <button
            className="w-full rounded-xl border border-red-200 px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-red-50"
            onClick={() => setShowNotes(true)}
            type="button"
          >
            Adicionar instruções de entrega (opcional)
          </button>
        )}

        <div>
          <p className="mb-2 text-xs font-semibold uppercase text-gray-500">Marque no mapa o ponto de entrega</p>
          {isGeocoding ? <p className="mb-2 text-xs text-gray-500">Atualizando mapa pelo endereço...</p> : null}
          <button
            className="mb-2 w-full rounded-lg border border-red-200 px-3 py-2 text-xs font-semibold text-primary hover:bg-red-50"
            onClick={() => updateMapFromAddress(buildCurrentAddress(), { withFeedback: true })}
            type="button"
          >
            Localizar no mapa
          </button>
          <MapPicker
            onChange={(location) => {
              const normalized = normalizeLocation(location);
              if (normalized != null) {
                setDeliveryLocation(normalized);
              }
            }}
            value={deliveryLocation}
          />
        </div>

        <button
          className="w-full rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700"
          disabled={createOrderMutation.isPending}
          onClick={placeOrder}
          type="button"
        >
          {createOrderMutation.isPending ? "Enviando pedido..." : "Finalizar pedido"}
        </button>
      </aside>
      </div>
    </div>
  );
}

export default CartPage;
