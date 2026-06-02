import api from "./api";

export const getStores = async (params = {}) => {
  const { data } = await api.get("/stores/", { params });
  return data;
};

export const getStoreById = async (id) => {
  const { data } = await api.get(`/stores/${id}/`);
  return data;
};

export const getStoreCategories = async () => {
  const { data } = await api.get("/stores/categories/");
  return data;
};

export const getMyStore = async () => {
  const { data } = await api.get("/stores/my-store/");
  return data;
};

export const createStore = async (payload) => {
  const { data } = await api.post("/stores/", payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};

export const updateStore = async (id, payload) => {
  const { data } = await api.patch(`/stores/${id}/`, payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};
