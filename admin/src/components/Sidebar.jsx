import {
  Home,
  Megaphone,
  Package,
  ShoppingCart,
  Store,
  Truck,
  Users,
} from 'lucide-react'
import { NavLink } from 'react-router-dom'

const items = [
  { to: '/dashboard', label: 'Dashboard', icon: Home },
  { to: '/users', label: 'Usuarios', icon: Users },
  { to: '/stores', label: 'Lojas', icon: Store },
  { to: '/products', label: 'Produtos', icon: Package },
  { to: '/orders', label: 'Pedidos', icon: ShoppingCart },
  { to: '/deliveries', label: 'Entregas', icon: Truck },
  { to: '/ads', label: 'Anuncios', icon: Megaphone },
]

function Sidebar() {
  return (
    <aside className="hidden w-72 border-r border-red-100 bg-white lg:block">
      <div className="border-b border-red-100 px-5 py-4">
        <img alt="Mercado Local" className="h-10 w-auto" src="/logo-mercado-local-horizontal-sem-fundo.png" />
        <p className="mt-2 text-xs font-semibold uppercase tracking-wide text-gray-500">Backoffice SaaS</p>
      </div>

      <nav className="space-y-1 p-3">
        {items.map((item) => {
          const Icon = item.icon
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-semibold transition ${
                  isActive ? 'bg-primary text-white' : 'text-gray-700 hover:bg-red-50'
                }`
              }
            >
              <Icon className="h-4 w-4" />
              {item.label}
            </NavLink>
          )
        })}
      </nav>
    </aside>
  )
}

export default Sidebar
