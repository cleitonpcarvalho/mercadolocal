import { LogOut, Search, ShoppingCart, Store } from "lucide-react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useState } from "react";

import { useAuth } from "../context/AuthContext";
import { useCartStore } from "../context/CartStore";

const BRAND_LOGO = "/logo-mercado-local-horizontal-sem-fundo.png";

function Header({ defaultSearch = "" }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, isAuthenticated, logout } = useAuth();
  const cartCount = useCartStore((state) =>
    state.items.reduce((acc, item) => acc + item.quantity, 0)
  );
  const [search, setSearch] = useState(defaultSearch);

  const submitSearch = (event) => {
    event.preventDefault();
    navigate(`/search?q=${encodeURIComponent(search.trim())}`);
  };

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <header className="sticky top-0 z-50 border-b border-red-100 bg-white/95 backdrop-blur">
      <div className="mx-auto flex max-w-7xl flex-wrap items-center gap-3 px-4 py-3 md:flex-nowrap md:px-6">
        <Link className="flex items-center gap-2" to="/">
          <img alt="Mercado Local" className="h-8 w-auto md:h-9" src={BRAND_LOGO} />
        </Link>

        <form className="relative min-w-[220px] flex-1" onSubmit={submitSearch}>
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            className="w-full rounded-full border border-red-100 bg-red-50/50 py-2.5 pl-10 pr-4 text-sm outline-none transition focus:border-primary"
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Busque produtos e lojas"
            value={search}
          />
        </form>

        <div className="ml-auto flex items-center gap-2 md:gap-3">
          <button
            className="relative rounded-full p-2 hover:bg-red-50"
            onClick={() => navigate("/cart")}
            type="button"
          >
            <ShoppingCart className="h-5 w-5 text-gray-700" />
            {cartCount > 0 ? (
              <span className="absolute -right-1 -top-1 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-xs font-semibold text-white">
                {cartCount}
              </span>
            ) : null}
          </button>

          {isAuthenticated ? (
            <div className="flex items-center gap-2">
              {user?.role === "store_owner" ? (
                <button
                  className="inline-flex items-center gap-1 rounded-lg border border-red-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-red-50"
                  onClick={() => navigate("/store-panel")}
                  type="button"
                >
                  <Store className="h-4 w-4" />
                  Painel
                </button>
              ) : null}
              <button
                className="inline-flex items-center gap-1 rounded-lg bg-gray-900 px-3 py-2 text-sm font-semibold text-white hover:bg-gray-700"
                onClick={handleLogout}
                type="button"
              >
                <LogOut className="h-4 w-4" />
                Sair
              </button>
            </div>
          ) : (
            <button
              className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
              onClick={() => navigate(`/login?next=${encodeURIComponent(location.pathname)}`)}
              type="button"
            >
              Entrar
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

export default Header;
