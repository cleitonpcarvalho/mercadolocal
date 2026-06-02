import { useMutation, useQuery } from "@tanstack/react-query";
import toast from "react-hot-toast";

import EmptyState from "../../components/EmptyState";
import LoadingSpinner from "../../components/LoadingSpinner";
import OrderStatusBadge from "../../components/OrderStatusBadge";
import { getOrders, updateOrderStatus } from "../../services/orderService";
import { extractListData, formatCurrencyBRL, getErrorMessage } from "../../utils/helpers";

const nextStatus = {
  pending: { value: "confirmed", label: "Confirmar pedido" },
  confirmed: { value: "preparing", label: "Iniciar preparação" },
  preparing: { value: "ready", label: "Marcar como pronto para retirada" },
};

const paymentMethodLabels = {
  pix: "Pix",
  credit_card: "Cartão de crédito",
  debit_card: "Cartão de débito",
};

const paymentStatusLabels = {
  pending: "Pendente",
  paid: "Pago",
  failed: "Falhou",
  refunded: "Reembolsado",
};

function StoreOrdersPage() {
  const ordersQuery = useQuery({
    queryKey: ["store-orders"],
    queryFn: () => getOrders(),
    refetchInterval: 15000,
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => updateOrderStatus(id, status),
    onSuccess: (payload) => {
      toast.success(payload?.message || "Status atualizado com sucesso.");
      ordersQuery.refetch();
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  if (ordersQuery.isLoading) return <LoadingSpinner label="Carregando pedidos..." />;

  const orders = extractListData(ordersQuery.data);

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-extrabold">Pedidos da loja</h1>

      {orders.length === 0 ? (
        <EmptyState description="Novos pedidos aparecerão aqui automaticamente." title="Sem pedidos" />
      ) : (
        <div className="space-y-3">
          {orders.map((order) => (
            <article className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm" key={order.id}>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-sm text-gray-500">Pedido #{order.id}</p>
                  <p className="font-semibold text-gray-900">{new Date(order.created_at).toLocaleString("pt-BR")}</p>
                </div>
                <OrderStatusBadge status={order.status} />
              </div>

              <div className="mt-4 grid gap-4 lg:grid-cols-2">
                <div className="space-y-2 text-sm text-gray-700">
                  <p>
                    <strong>Cliente:</strong> {order.customer_name || "-"}
                  </p>
                  <p>
                    <strong>Telefone:</strong> {order.customer_phone || "-"}
                  </p>
                  <p>
                    <strong>E-mail:</strong> {order.customer_email || "-"}
                  </p>
                  <p>
                    <strong>Endereço:</strong> {order.delivery_address || "-"}
                  </p>
                  <p>
                    <strong>Pagamento:</strong> {paymentMethodLabels[order.payment_method] || order.payment_method}
                    {" · "}
                    {paymentStatusLabels[order.payment_status] || order.payment_status}
                  </p>
                  <p>
                    <strong>Observações:</strong> {order.notes?.trim() ? order.notes : "Sem observações."}
                  </p>
                </div>

                <div className="space-y-2">
                  <p className="text-xs font-semibold uppercase text-gray-500">Itens do pedido</p>
                  {order.items?.length ? (
                    <div className="space-y-1 text-sm">
                      {order.items.map((item) => (
                        <div className="flex items-center justify-between" key={`${order.id}-${item.id}`}>
                          <span className="text-gray-700">
                            {item.quantity}x {item.product_name}
                          </span>
                          <strong className="text-gray-900">{formatCurrencyBRL(item.subtotal)}</strong>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-gray-500">Itens não informados.</p>
                  )}

                  <div className="mt-3 rounded-xl bg-gray-50 p-3 text-sm">
                    <div className="flex justify-between">
                      <span>Subtotal</span>
                      <strong>{formatCurrencyBRL(order.subtotal)}</strong>
                    </div>
                    <div className="mt-1 flex justify-between">
                      <span>Entrega</span>
                      <strong>{formatCurrencyBRL(order.delivery_fee)}</strong>
                    </div>
                    <div className="mt-1 flex justify-between">
                      <span>Comissão</span>
                      <strong>{formatCurrencyBRL(order.commission_fee)}</strong>
                    </div>
                    <div className="mt-2 flex justify-between border-t border-gray-200 pt-2 text-base">
                      <span className="font-semibold">Total</span>
                      <strong>{formatCurrencyBRL(order.total)}</strong>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-4 flex flex-wrap items-center justify-end gap-2">
                {nextStatus[order.status] ? (
                  <button
                    className="rounded-xl bg-primary px-3 py-2 text-xs font-semibold text-white hover:bg-red-700"
                    disabled={statusMutation.isPending}
                    onClick={() =>
                      statusMutation.mutate({
                        id: order.id,
                        status: nextStatus[order.status].value,
                      })
                    }
                    type="button"
                  >
                    {nextStatus[order.status].label}
                  </button>
                ) : (
                  <p className="text-xs text-gray-500">Fluxo concluído para este pedido.</p>
                )}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}

export default StoreOrdersPage;
