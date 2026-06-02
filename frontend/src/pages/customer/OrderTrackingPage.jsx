import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Bike, Clock, MapPin } from "lucide-react";
import { MapContainer, Marker, Polyline, TileLayer } from "react-leaflet";
import { useNavigate, useParams } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import OrderStatusBadge from "../../components/OrderStatusBadge";
import { getOrderById } from "../../services/orderService";
import { extractSingleData, formatCurrencyBRL } from "../../utils/helpers";

const steps = [
  "pending",
  "confirmed",
  "preparing",
  "ready",
  "in_delivery",
  "delivered",
];

const STEP_LABELS = {
  pending: "Pendente",
  confirmed: "Confirmado",
  preparing: "Em preparação",
  ready: "Aguardando entregador",
  in_delivery: "Em entrega",
  delivered: "Entregue",
};

function OrderTrackingPage() {
  const navigate = useNavigate();
  const { id } = useParams();

  const orderQuery = useQuery({
    queryKey: ["order-tracking", id],
    queryFn: () => getOrderById(id),
    refetchInterval: 10000,
    enabled: Boolean(id),
  });

  const order = extractSingleData(orderQuery.data);

  if (orderQuery.isLoading) return <LoadingSpinner label="Carregando rastreio..." />;
  if (!order) return <EmptyState description="Não foi possível localizar este pedido." title="Pedido não encontrado" />;

  const currentStep = steps.indexOf(order.status);
  const delivery = order.delivery;
  const storePoint = delivery
    ? [Number(delivery.pickup_latitude), Number(delivery.pickup_longitude)]
    : [Number(order.delivery_latitude), Number(order.delivery_longitude)];
  const customerPoint = [Number(order.delivery_latitude), Number(order.delivery_longitude)];
  const driverPoint = delivery?.driver_latitude
    ? [Number(delivery.driver_latitude), Number(delivery.driver_longitude)]
    : null;

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

      <section className="rounded-3xl border border-red-100 bg-white p-5 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-extrabold">Pedido #{order.id}</h1>
            <p className="text-sm text-gray-500">{order.store_name}</p>
          </div>
          <OrderStatusBadge status={order.status} />
        </div>

        <div className="mt-5 grid gap-3 md:grid-cols-2">
          {steps.map((step, index) => (
            <div
              className={`rounded-xl border p-3 text-sm ${
                index <= currentStep
                  ? "border-primary bg-red-50 text-primary"
                  : "border-gray-200 bg-gray-50 text-gray-500"
              }`}
              key={step}
            >
              {STEP_LABELS[step] || step}
            </div>
          ))}
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <div className="rounded-3xl border border-red-100 bg-white p-4 shadow-sm">
          <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-gray-700">
            <MapPin className="h-4 w-4 text-primary" />
            Localização da entrega
          </div>

          <MapContainer center={customerPoint} style={{ height: "420px", width: "100%" }} zoom={13}>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <Marker position={storePoint} />
            <Marker position={customerPoint} />
            {driverPoint ? <Marker position={driverPoint} /> : null}
            <Polyline positions={driverPoint ? [driverPoint, customerPoint] : [storePoint, customerPoint]} />
          </MapContainer>
        </div>

        <aside className="space-y-4">
          <div className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
            <p className="text-xs font-semibold uppercase text-gray-500">Itens</p>
            <div className="mt-2 space-y-2">
              {order.items?.map((item) => (
                <div className="flex justify-between text-sm" key={item.id}>
                  <span>
                    {item.quantity}x {item.product_name}
                  </span>
                  <strong>{formatCurrencyBRL(item.subtotal)}</strong>
                </div>
              ))}
            </div>
            <div className="mt-3 border-t border-red-100 pt-3 text-right text-lg font-extrabold">
              {formatCurrencyBRL(order.total)}
            </div>
          </div>

          <div className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
            <p className="text-xs font-semibold uppercase text-gray-500">Entrega</p>
            <p className="mt-2 text-sm text-gray-700">{order.delivery_address}</p>
            {delivery?.driver ? (
              <p className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-primary">
                <Bike className="h-4 w-4" />
                Entregador #{delivery.driver}
              </p>
            ) : (
              <p className="mt-2 inline-flex items-center gap-1 text-sm text-gray-500">
                <Clock className="h-4 w-4" />
                Aguardando entregador
              </p>
            )}
          </div>
        </aside>
      </section>
    </div>
  );
}

export default OrderTrackingPage;
