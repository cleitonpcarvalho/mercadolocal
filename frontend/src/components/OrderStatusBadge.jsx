import { statusColorMap } from "../utils/helpers";

const statusLabelMap = {
  pending: "Pendente",
  confirmed: "Confirmado",
  preparing: "Preparando",
  ready: "Aguardando entregador",
  in_delivery: "Em entrega",
  delivered: "Entregue",
  cancelled: "Cancelado",
  waiting: "Aguardando entregador",
  accepted: "Entregador a caminho",
  picked_up: "Saiu para entrega",
  failed: "Falha na entrega",
};

function OrderStatusBadge({ status }) {
  const css = statusColorMap[status] || "bg-gray-100 text-gray-700";

  return (
    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${css}`}>
      {statusLabelMap[status] || "Status"}
    </span>
  );
}

export default OrderStatusBadge;
