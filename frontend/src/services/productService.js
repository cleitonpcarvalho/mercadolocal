import api from "./api";

export const getProducts = async (params = {}) => {
  const { data } = await api.get("/products/", { params });
  return data;
};

export const getProductById = async (id) => {
  const { data } = await api.get(`/products/${id}/`);
  return data;
};

export const getMyProducts = async () => {
  const { data } = await api.get("/products/my-products/");
  return data;
};

export const getCategoryTree = async () => {
  const { data } = await api.get("/products/categories/");
  return data;
};

export const createProduct = async (payload) => {
  const { data } = await api.post("/products/", payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};

export const updateProduct = async (id, payload) => {
  const { data } = await api.patch(`/products/${id}/`, payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};

export const deleteProduct = async (id) => {
  const { data } = await api.delete(`/products/${id}/`);
  return data;
};
