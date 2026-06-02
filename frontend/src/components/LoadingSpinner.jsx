import { LoaderCircle } from "lucide-react";

function LoadingSpinner({ label = "Carregando..." }) {
  return (
    <div className="flex min-h-[180px] items-center justify-center gap-3 text-gray-600">
      <LoaderCircle className="h-6 w-6 animate-spin text-primary" />
      <span className="text-sm font-medium">{label}</span>
    </div>
  );
}

export default LoadingSpinner;
