import api from "./api";

export const getActiveAds = async (params = {}) => {
  const { data } = await api.get("/ads/active/", { params });
  return data;
};

export const registerAdClick = async (id) => {
  const { data } = await api.post(`/ads/${id}/click/`);
  return data;
};

export const createAd = async (payload) => {
  const { data } = await api.post("/ads/", payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};

export const getMyAds = async () => {
  const { data } = await api.get("/ads/my-ads/");
  return data;
};
