import { useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import OrderStatusBadge from "../../components/OrderStatusBadge";
import { getOrders } from "../../services/orderService";
import { extractListData, formatCurrencyBRL } from "../../utils/helpers";

function CustomerOrdersPage() {
  const navigate = useNavigate();

  const ordersQuery = useQuery({
    queryKey: ["customer-orders"],
    queryFn: () => getOrders(),
  });

  const orders = extractListData(ordersQuery.data);

  if (ordersQuery.isLoading) return <LoadingSpinner label="Carregando pedidos..." />;

  return (
    <section className="space-y-4">
      <button
        className="inline-flex items-center gap-1 text-sm font-semibold text-primary"
        onClick={() => navigate(-1)}
        type="button"
      >
        <ArrowLeft className="h-4 w-4" />
        Voltar
      </button>

      <h1 className="text-2xl font-extrabold">Meus pedidos</h1>

      {orders.length === 0 ? (
        <EmptyState description="Quando você fizer seu primeiro pedido, ele aparecerá aqui." title="Nenhum pedido ainda" />
      ) : (
        <div className="space-y-3">
          {orders.map((order) => (
            <Link
              className="block rounded-2xl border border-red-100 bg-white p-4 shadow-sm transition hover:-translate-y-0.5"
              key={order.id}
              to={`/orders/${order.id}`}
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-sm text-gray-500">Pedido #{order.id}</p>
                  <p className="font-bold text-gray-900">{order.store_name}</p>
                  <p className="text-xs text-gray-500">
                    {new Date(order.created_at).toLocaleString("pt-BR")}
                  </p>
                </div>
                <div className="text-right">
                  <OrderStatusBadge status={order.status} />
                  <p className="mt-2 text-base font-extrabold text-gray-900">
                    {formatCurrencyBRL(order.total)}
                  </p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </section>
  );
}

export default CustomerOrdersPage;
