import { Outlet } from "react-router-dom";

import Footer from "../../components/Footer";
import Header from "../../components/Header";

function CustomerLayout() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-red-50/40 text-gray-900">
      <Header />
      <main className="mx-auto w-full max-w-7xl px-4 py-6 md:px-6">
        <Outlet />
      </main>
      <Footer />
    </div>
  );
}

export default CustomerLayout;
