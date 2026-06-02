import { LogOut } from 'lucide-react'

function Header({ title, userName, onLogout }) {
  return (
    <header className="flex items-center justify-between border-b border-red-100 bg-white px-4 py-4 sm:px-6">
      <div>
        <h1 className="text-xl font-black text-gray-900">{title}</h1>
        <p className="text-sm text-gray-500">Painel administrativo da plataforma</p>
      </div>

      <div className="flex items-center gap-3">
        <div className="hidden text-right sm:block">
          <p className="text-sm font-bold text-gray-900">{userName || 'Administrador'}</p>
          <p className="text-xs uppercase tracking-wide text-gray-500">Admin</p>
        </div>
        <button
          className="inline-flex items-center gap-1 rounded-lg bg-gray-900 px-3 py-2 text-sm font-semibold text-white hover:bg-gray-700"
          onClick={onLogout}
          type="button"
        >
          <LogOut className="h-4 w-4" />
          Sair
        </button>
      </div>
    </header>
  )
}

export default Header
