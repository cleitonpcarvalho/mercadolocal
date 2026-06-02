function ConfirmDialog({ open, title, description, confirmText = 'Confirmar', cancelText = 'Cancelar', onConfirm, onCancel, loading = false }) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 px-4">
      <div className="w-full max-w-md rounded-2xl border border-red-100 bg-white p-5 shadow-xl">
        <h3 className="text-lg font-bold text-gray-900">{title}</h3>
        <p className="mt-2 text-sm text-gray-600">{description}</p>
        <div className="mt-5 flex items-center justify-end gap-2">
          <button
            className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50"
            onClick={onCancel}
            type="button"
          >
            {cancelText}
          </button>
          <button
            className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60"
            disabled={loading}
            onClick={onConfirm}
            type="button"
          >
            {loading ? 'Processando...' : confirmText}
          </button>
        </div>
      </div>
    </div>
  )
}

export default ConfirmDialog
