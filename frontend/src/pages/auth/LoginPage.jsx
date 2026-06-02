import { useMutation } from "@tanstack/react-query";
import { ArrowLeft, LogIn } from "lucide-react";
import { useState } from "react";
import toast from "react-hot-toast";
import { Link, useLocation, useNavigate } from "react-router-dom";

import { useAuth } from "../../context/AuthContext";
import { loginRequest } from "../../services/authService";
import { getErrorMessage } from "../../utils/helpers";

function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();

  const [form, setForm] = useState({ email: "", password: "" });

  const mutation = useMutation({
    mutationFn: loginRequest,
    onSuccess: (payload) => {
      const authData = payload?.data || {};
      const role = authData.user?.role;
      if (role === "admin") {
        const authHash = encodeURIComponent(JSON.stringify(authData));
        window.location.href = `http://localhost:5181/admin/login#auth=${authHash}`;
        return;
      }

      login(authData);
      toast.success(payload?.message || "Login realizado com sucesso!");

      if (role === "store_owner") {
        navigate("/store-panel");
        return;
      }

      if (role === "delivery_driver") {
        toast("Motoristas usam o app mobile de entregas.");
      }

      const next = new URLSearchParams(location.search).get("next");
      navigate(next || "/");
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const onSubmit = (event) => {
    event.preventDefault();
    mutation.mutate(form);
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-to-br from-red-50 via-white to-red-100 px-4 py-10">
      <div className="pointer-events-none absolute -left-24 -top-24 h-72 w-72 rounded-full bg-red-200/40 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -right-20 h-80 w-80 rounded-full bg-red-300/30 blur-3xl" />

      <div className="relative w-full max-w-4xl rounded-3xl border border-red-100 bg-white/95 shadow-2xl backdrop-blur">
        <div className="grid md:grid-cols-[1.1fr_1fr]">
          <section className="hidden rounded-l-3xl bg-gradient-to-br from-primary to-red-700 p-8 text-white md:flex md:flex-col md:justify-between">
            <div>
              <img
                alt="Mercado Local"
                className="h-12 w-auto rounded-xl bg-white p-2"
                src="/logo-mercado-local-horizontal-sem-fundo.png"
              />
              <h2 className="mt-8 text-4xl font-black leading-tight">Compre nas lojas da sua cidade em minutos</h2>
              <p className="mt-4 text-sm font-medium text-red-50">
                Acesse para acompanhar pedidos, salvar endereços e finalizar suas compras com mais rapidez.
              </p>
            </div>
            <p className="text-xs font-semibold uppercase tracking-wide text-red-100">Mercado Local</p>
          </section>

          <section className="p-6 sm:p-8">
            <button
              className="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:underline"
              onClick={() => navigate(-1)}
              type="button"
            >
              <ArrowLeft className="h-4 w-4" />
              Voltar
            </button>

            <img
              alt="Mercado Local"
              className="mx-auto mt-4 h-14 w-auto md:hidden"
              src="/logo-mercado-local-horizontal-sem-fundo.png"
            />

            <h1 className="mt-4 text-2xl font-extrabold text-gray-900">Entrar</h1>
            <p className="mt-1 text-sm text-gray-500">Entre para finalizar compras e acompanhar seus pedidos.</p>

            <form className="mt-6 space-y-4" onSubmit={onSubmit}>
              <input
                className="w-full rounded-xl border border-red-100 bg-red-50/30 px-4 py-3 outline-none transition focus:border-primary"
                onChange={(event) => setForm((state) => ({ ...state, email: event.target.value }))}
                placeholder="Email"
                required
                type="email"
                value={form.email}
              />
              <input
                className="w-full rounded-xl border border-red-100 bg-red-50/30 px-4 py-3 outline-none transition focus:border-primary"
                minLength={8}
                onChange={(event) => setForm((state) => ({ ...state, password: event.target.value }))}
                placeholder="Senha"
                required
                type="password"
                value={form.password}
              />

              <button
                className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700 disabled:opacity-60"
                disabled={mutation.isPending}
                type="submit"
              >
                <LogIn className="h-4 w-4" />
                {mutation.isPending ? "Entrando..." : "Entrar"}
              </button>
            </form>

            <p className="mt-5 text-sm text-gray-500">
              Não possui conta?{" "}
              <Link className="font-semibold text-primary hover:underline" to="/register">
                Cadastre-se
              </Link>
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
