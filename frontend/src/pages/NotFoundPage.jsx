import { Link } from "react-router-dom";

function NotFoundPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-red-50 px-4 text-center">
      <p className="text-sm font-semibold uppercase tracking-wide text-primary">404</p>
      <h1 className="text-3xl font-black text-gray-900">Página não encontrada</h1>
      <Link className="rounded-xl bg-primary px-5 py-3 font-semibold text-white hover:bg-red-700" to="/">
        Voltar para início
      </Link>
    </div>
  );
}

export default NotFoundPage;
