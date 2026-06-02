import { PackageSearch } from "lucide-react";

function EmptyState({ title = "Nada encontrado", description = "Tente outro filtro." }) {
  return (
    <div className="rounded-2xl border border-red-100 bg-white p-8 text-center shadow-sm">
      <PackageSearch className="mx-auto mb-3 h-10 w-10 text-primary" />
      <h3 className="text-lg font-bold text-gray-900">{title}</h3>
      <p className="mt-2 text-sm text-gray-500">{description}</p>
    </div>
  );
}

export default EmptyState;
