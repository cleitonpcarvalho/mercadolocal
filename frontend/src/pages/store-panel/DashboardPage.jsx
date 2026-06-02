import { useQuery } from "@tanstack/react-query";

import LoadingSpinner from "../../components/LoadingSpinner";
import OrderStatusBadge from "../../components/OrderStatusBadge";
import { getOrders } from "../../services/orderService";
import { getMyProducts } from "../../services/productService";
import { extractListData, formatCurrencyBRL } from "../../utils/helpers";

function DashboardPage() {
  const ordersQuery = useQuery({
    queryKey: ["store-orders-dashboard"],
    queryFn: () => getOrders(),
    refetchInterval: 15000,
  });

  const productsQuery = useQuery({
    queryKey: ["store-products-dashboard"],
    queryFn: getMyProducts,
  });

  if (ordersQuery.isLoading || productsQuery.isLoading) {
    return <LoadingSpinner label="Carregando painel..." />;
  }

  const orders = extractListData(ordersQuery.data);
  const products = extractListData(productsQuery.data);

  const today = new Date().toDateString();
  const todaysOrders = orders.filter((order) => new Date(order.created_at).toDateString() === today);
  const revenueToday = todaysOrders.reduce((sum, order) => sum + Number(order.total || 0), 0);

  const metrics = [
    { label: "Pedidos hoje", value: todaysOrders.length },
    { label: "Receita hoje", value: formatCurrencyBRL(revenueToday) },
    { label: "Pedidos pendentes", value: orders.filter((order) => order.status === "pending").length },
    { label: "Produtos ativos", value: products.filter((product) => product.is_available).length },
  ];

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-extrabold">Painel</h1>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {metrics.map((item) => (
          <article className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm" key={item.label}>
            <p className="text-xs font-semibold uppercase text-gray-500">{item.label}</p>
            <p className="mt-2 text-2xl font-black text-gray-900">{item.value}</p>
          </article>
        ))}
      </div>

      <section className="rounded-2xl border border-red-100 bg-white p-4 shadow-sm">
        <h2 className="text-lg font-bold">Pedidos recentes</h2>
        <div className="mt-3 overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="border-b border-red-100 text-left text-gray-500">
                <th className="py-2">Pedido</th>
                <th className="py-2">Data</th>
                <th className="py-2">Status</th>
                <th className="py-2 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {orders.slice(0, 8).map((order) => (
                <tr className="border-b border-red-50" key={order.id}>
                  <td className="py-2 font-semibold">#{order.id}</td>
                  <td className="py-2">{new Date(order.created_at).toLocaleString("pt-BR")}</td>
                  <td className="py-2">
                    <OrderStatusBadge status={order.status} />
                  </td>
                  <td className="py-2 text-right font-bold">{formatCurrencyBRL(order.total)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

export default DashboardPage;
