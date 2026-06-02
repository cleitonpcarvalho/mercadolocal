import { useMutation } from "@tanstack/react-query";
import { UserPlus } from "lucide-react";
import { useState } from "react";
import toast from "react-hot-toast";
import { Link, useNavigate } from "react-router-dom";

import { useAuth } from "../../context/AuthContext";
import { registerRequest } from "../../services/authService";
import { getErrorMessage } from "../../utils/helpers";

function RegisterPage() {
  const navigate = useNavigate();
  const { login } = useAuth();

  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
    phone: "",
    role: "customer",
    city: "",
    state: "",
  });

  const mutation = useMutation({
    mutationFn: registerRequest,
    onSuccess: (payload) => {
      const authData = payload?.data || {};
      login(authData);
      toast.success(payload?.message || "Conta criada com sucesso!");
      navigate("/");
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const onSubmit = (event) => {
    event.preventDefault();

    if (form.password !== form.confirmPassword) {
      toast.error("As senhas não coincidem.");
      return;
    }

    mutation.mutate({
      name: form.name,
      email: form.email,
      password: form.password,
      phone: form.phone,
      role: form.role,
      city: form.city,
      state: form.state,
    });
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-b from-red-50 to-white px-4 py-10">
      <div className="w-full max-w-xl rounded-3xl border border-red-100 bg-white p-7 shadow-lg">
        <img
          alt="Mercado Local"
          className="mx-auto mb-4 h-14 w-auto"
          src="/logo-mercado-local-horizontal-sem-fundo.png"
        />
        <h1 className="text-2xl font-extrabold text-gray-900">Criar conta</h1>
          <p className="mt-1 text-sm text-gray-500">Cadastre-se para comprar ou vender localmente</p>

        <form className="mt-6 grid gap-4 md:grid-cols-2" onSubmit={onSubmit}>
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary md:col-span-2"
            onChange={(event) => setForm((state) => ({ ...state, name: event.target.value }))}
            placeholder="Nome completo"
            required
            type="text"
            value={form.name}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary md:col-span-2"
            onChange={(event) => setForm((state) => ({ ...state, email: event.target.value }))}
            placeholder="Email"
            required
            type="email"
            value={form.email}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            minLength={8}
            onChange={(event) => setForm((state) => ({ ...state, password: event.target.value }))}
            placeholder="Senha"
            required
            type="password"
            value={form.password}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            minLength={8}
            onChange={(event) =>
              setForm((state) => ({ ...state, confirmPassword: event.target.value }))
            }
            placeholder="Confirmar senha"
            required
            type="password"
            value={form.confirmPassword}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            onChange={(event) => setForm((state) => ({ ...state, phone: event.target.value }))}
            placeholder="Telefone"
            required
            type="text"
            value={form.phone}
          />
          <select
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            onChange={(event) => setForm((state) => ({ ...state, role: event.target.value }))}
            value={form.role}
          >
            <option value="customer">Cliente</option>
            <option value="store_owner">Dono de loja</option>
          </select>
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            onChange={(event) => setForm((state) => ({ ...state, city: event.target.value }))}
            placeholder="Cidade"
            required
            type="text"
            value={form.city}
          />
          <input
            className="rounded-xl border border-red-100 px-4 py-3 outline-none focus:border-primary"
            onChange={(event) => setForm((state) => ({ ...state, state: event.target.value }))}
            placeholder="Estado"
            required
            type="text"
            value={form.state}
          />

          <button
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700 md:col-span-2"
            disabled={mutation.isPending}
            type="submit"
          >
            <UserPlus className="h-4 w-4" />
            {mutation.isPending ? "Criando conta..." : "Criar conta"}
          </button>
        </form>

        <p className="mt-5 text-sm text-gray-500">
          Já possui conta?{" "}
          <Link className="font-semibold text-primary hover:underline" to="/login">
            Entrar
          </Link>
        </p>
      </div>
    </div>
  );
}

export default RegisterPage;
