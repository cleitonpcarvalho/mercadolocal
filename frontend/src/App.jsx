import { Navigate, Route, Routes } from "react-router-dom";

import ProtectedRoute from "./components/ProtectedRoute";
import StoreOwnerRoute from "./components/StoreOwnerRoute";
import LoginPage from "./pages/auth/LoginPage";
import RegisterPage from "./pages/auth/RegisterPage";
import NotFoundPage from "./pages/NotFoundPage";
import CartPage from "./pages/customer/CartPage";
import CustomerLayout from "./pages/customer/CustomerLayout";
import CustomerOrdersPage from "./pages/customer/CustomerOrdersPage";
import HomePage from "./pages/customer/HomePage";
import OrderTrackingPage from "./pages/customer/OrderTrackingPage";
import ProductDetailPage from "./pages/customer/ProductDetailPage";
import SearchResultsPage from "./pages/customer/SearchResultsPage";
import StorePage from "./pages/customer/StorePage";
import AdsPage from "./pages/store-panel/AdsPage";
import DashboardPage from "./pages/store-panel/DashboardPage";
import MyStorePage from "./pages/store-panel/MyStorePage";
import ProductFormPage from "./pages/store-panel/ProductFormPage";
import ProductsPage from "./pages/store-panel/ProductsPage";
import SettingsPage from "./pages/store-panel/SettingsPage";
import StoreOrdersPage from "./pages/store-panel/StoreOrdersPage";
import StorePanelLayout from "./pages/store-panel/StorePanelLayout";

function App() {
  return (
    <Routes>
      <Route element={<CustomerLayout />}>
        <Route element={<HomePage />} path="/" />
        <Route element={<SearchResultsPage />} path="/search" />
        <Route element={<ProductDetailPage />} path="/product/:id" />
        <Route element={<StorePage />} path="/store/:id" />
        <Route element={<CartPage />} path="/cart" />

        <Route
          element={
            <ProtectedRoute>
              <CustomerOrdersPage />
            </ProtectedRoute>
          }
          path="/orders"
        />

        <Route
          element={
            <ProtectedRoute>
              <OrderTrackingPage />
            </ProtectedRoute>
          }
          path="/orders/:id"
        />
      </Route>

      <Route element={<LoginPage />} path="/login" />
      <Route element={<RegisterPage />} path="/register" />

      <Route
        element={
          <StoreOwnerRoute>
            <StorePanelLayout />
          </StoreOwnerRoute>
        }
        path="/store-panel"
      >
        <Route element={<DashboardPage />} index />
        <Route element={<MyStorePage />} path="store" />
        <Route element={<ProductsPage />} path="products" />
        <Route element={<ProductFormPage />} path="products/new" />
        <Route element={<ProductFormPage />} path="products/:id/edit" />
        <Route element={<StoreOrdersPage />} path="orders" />
        <Route element={<AdsPage />} path="ads" />
        <Route element={<SettingsPage />} path="settings" />
      </Route>

      <Route element={<Navigate replace to="/store-panel" />} path="/store-panel/" />
      <Route element={<NotFoundPage />} path="*" />
    </Routes>
  );
}

export default App;
