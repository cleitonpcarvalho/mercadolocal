import { LayoutDashboard, Megaphone, Package, Settings, Store, Truck } from "lucide-react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";

import { useAuth } from "../../context/AuthContext";

const links = [
  { to: "/store-panel", label: "Painel", icon: LayoutDashboard, end: true },
  { to: "/store-panel/store", label: "Minha loja", icon: Store },
  { to: "/store-panel/products", label: "Produtos", icon: Package },
  { to: "/store-panel/orders", label: "Pedidos", icon: Truck },
  { to: "/store-panel/ads", label: "Anúncios", icon: Megaphone },
  { to: "/store-panel/settings", label: "Configurações", icon: Settings },
];

function StorePanelLayout() {
  const navigate = useNavigate();
  const { logout, user } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="mx-auto grid max-w-7xl gap-5 px-4 py-6 lg:grid-cols-[260px_1fr] lg:px-6">
        <aside className="h-fit rounded-3xl border border-red-100 bg-white p-4 shadow-sm">
          <div className="mb-4 border-b border-red-100 pb-4">
            <p className="text-xs uppercase text-gray-500">Painel da loja</p>
            <p className="text-lg font-bold text-gray-900">{user?.name || user?.email}</p>
          </div>

          <nav className="space-y-1">
            {links.map((link) => (
              <NavLink
                className={({ isActive }) =>
                  `flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold transition ${
                    isActive
                      ? "bg-primary text-white"
                      : "text-gray-700 hover:bg-red-50 hover:text-primary"
                  }`
                }
                end={link.end}
                key={link.to}
                to={link.to}
              >
                <link.icon className="h-4 w-4" />
                {link.label}
              </NavLink>
            ))}
          </nav>

          <button
            className="mt-5 w-full rounded-xl border border-red-100 px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-red-50"
            onClick={() => {
              logout();
              navigate("/login");
            }}
            type="button"
          >
            Sair
          </button>
        </aside>

        <main className="space-y-5">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export default StorePanelLayout;
