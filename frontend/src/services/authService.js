import api from "./api";

export const loginRequest = async (payload) => {
  const { data } = await api.post("/users/login/", payload);
  return data;
};

export const registerRequest = async (payload) => {
  const { data } = await api.post("/users/register/", payload);
  return data;
};

export const refreshTokenRequest = async (refresh) => {
  const { data } = await api.post("/users/token/refresh/", { refresh });
  return data;
};

export const logoutRequest = async (refresh) => {
  const { data } = await api.post("/users/logout/", { refresh });
  return data;
};

export const meRequest = async () => {
  const { data } = await api.get("/users/me/");
  return data;
};

export const updateMeRequest = async (payload) => {
  const { data } = await api.patch("/users/me/", payload, {
    headers:
      payload instanceof FormData
        ? {
            "Content-Type": "multipart/form-data",
          }
        : undefined,
  });
  return data;
};

export const changePasswordRequest = async (payload) => {
  const { data } = await api.post("/users/change-password/", payload);
  return data;
};
