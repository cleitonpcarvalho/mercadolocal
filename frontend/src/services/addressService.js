const VIA_CEP_URL = "https://viacep.com.br/ws";
const NOMINATIM_URL = "https://nominatim.openstreetmap.org/search";

export const sanitizeCep = (value = "") => value.replace(/\D/g, "").slice(0, 8);

export const formatCep = (value = "") => {
  const digits = sanitizeCep(value);
  if (digits.length <= 5) return digits;
  return `${digits.slice(0, 5)}-${digits.slice(5)}`;
};

export const buildDeliveryAddress = ({
  street = "",
  number = "",
  complement = "",
  neighborhood = "",
  city = "",
  state = "",
  cep = "",
}) => {
  const firstLine = [street, number].filter(Boolean).join(", ");
  const cityState = [city, state].filter(Boolean).join(" - ");
  const cepLabel = cep ? `CEP ${formatCep(cep)}` : "";

  return [firstLine, complement, neighborhood, cityState, cepLabel].filter(Boolean).join(", ");
};

export const fetchAddressByCep = async (cep) => {
  const cleanCep = sanitizeCep(cep);
  if (cleanCep.length !== 8) {
    throw new Error("Informe um CEP válido com 8 dígitos.");
  }

  const response = await fetch(`${VIA_CEP_URL}/${cleanCep}/json/`);
  if (!response.ok) {
    throw new Error("Não foi possível consultar o CEP.");
  }

  const data = await response.json();
  if (data?.erro) {
    throw new Error("CEP não encontrado.");
  }

  return {
    cep: formatCep(cleanCep),
    street: data?.logradouro || "",
    complement: data?.complemento || "",
    neighborhood: data?.bairro || "",
    city: data?.localidade || "",
    state: data?.uf || "",
  };
};

export const geocodeAddress = async (address) => {
  const query = `${address || ""}`.trim();
  if (!query) return null;

  const params = new URLSearchParams({
    format: "jsonv2",
    limit: "1",
    addressdetails: "1",
    q: query,
  });

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 6000);

  let response;
  try {
    response = await fetch(`${NOMINATIM_URL}?${params.toString()}`, {
      headers: {
        Accept: "application/json",
        "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.8",
      },
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    throw new Error("Não foi possível localizar o endereço no mapa.");
  }

  const data = await response.json();
  if (!Array.isArray(data) || !data.length) {
    return null;
  }

  const first = data[0];
  const lat = Number(first?.lat);
  const lng = Number(first?.lon);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return { lat, lng };
};
