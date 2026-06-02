import api from "./api";

export const getAvailableDeliveries = async () => {
  const { data } = await api.get("/deliveries/available/");
  return data;
};

export const getMyDeliveries = async () => {
  const { data } = await api.get("/deliveries/my-deliveries/");
  return data;
};

export const acceptDelivery = async (id) => {
  const { data } = await api.post(`/deliveries/${id}/accept/`);
  return data;
};

export const updateDeliveryStatus = async (id, status) => {
  const { data } = await api.patch(`/deliveries/${id}/status/`, { status });
  return data;
};

export const updateDeliveryLocation = async (id, payload) => {
  const { data } = await api.patch(`/deliveries/${id}/location/`, payload);
  return data;
};

export const rateDelivery = async (id, payload) => {
  const { data } = await api.post(`/deliveries/${id}/rate/`, payload);
  return data;
};
