import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useMemo } from 'react'
import { Toaster } from 'react-hot-toast'
import {
  BrowserRouter,
  Navigate,
  Outlet,
  Route,
  Routes,
  useLocation,
  useNavigate,
} from 'react-router-dom'

import Header from './components/Header'
import Sidebar from './components/Sidebar'
import { useAuth } from './context/AuthContext'
import AdsPage from './pages/AdsPage'
import DashboardPage from './pages/DashboardPage'
import DeliveriesPage from './pages/DeliveriesPage'
import LoginPage from './pages/LoginPage'
import OrdersPage from './pages/OrdersPage'
import ProductsPage from './pages/ProductsPage'
import StoresPage from './pages/StoresPage'
import UsersPage from './pages/UsersPage'
import { logoutRequest } from './services/auth'

const queryClient = new QueryClient()

const titleMap = {
  '/dashboard': 'Dashboard',
  '/users': 'Usuarios',
  '/stores': 'Lojas',
  '/products': 'Produtos',
  '/orders': 'Pedidos',
  '/deliveries': 'Entregas',
  '/ads': 'Anuncios',
}

function RedirectToMainSite() {
  if (typeof window !== 'undefined') {
    window.location.replace('http://localhost:5180/')
  }
  return null
}

function ProtectedRoute() {
  const { isAuthenticated, isAdmin } = useAuth()

  if (!isAuthenticated) {
    return <Navigate replace to="/admin/login" />
  }

  if (!isAdmin) {
    return <Navigate replace to="/admin/login" />
  }

  return <Outlet />
}

function AdminLayout() {
  const navigate = useNavigate()
  const location = useLocation()
  const { user, refreshToken, logout } = useAuth()

  const title = useMemo(() => titleMap[location.pathname] || 'Dashboard', [location.pathname])

  const handleLogout = async () => {
    try {
      if (refreshToken) {
        await logoutRequest(refreshToken)
      }
    } catch (error) {
      // Ignore logout API error and clear local auth anyway.
    } finally {
      logout()
      navigate('/admin/login', { replace: true })
    }
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <Header title={title} userName={user?.name || user?.email} onLogout={handleLogout} />
        <main className="min-h-0 flex-1 overflow-y-auto p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

function AppRoutes() {
  return (
    <Routes>
      <Route element={<RedirectToMainSite />} path="/" />
      <Route element={<RedirectToMainSite />} path="/login" />
      <Route element={<LoginPage />} path="/admin/login" />

      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route element={<DashboardPage />} path="/dashboard" />
          <Route element={<UsersPage />} path="/users" />
          <Route element={<StoresPage />} path="/stores" />
          <Route element={<ProductsPage />} path="/products" />
          <Route element={<OrdersPage />} path="/orders" />
          <Route element={<DeliveriesPage />} path="/deliveries" />
          <Route element={<AdsPage />} path="/ads" />
        </Route>
      </Route>

      <Route element={<Navigate replace to="/" />} path="*" />
    </Routes>
  )
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
      <Toaster position="top-right" />
    </QueryClientProvider>
  )
}

export default App
