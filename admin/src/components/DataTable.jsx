function DataTable({ columns, rows, loading, emptyMessage = 'Nenhum registro encontrado.', rowClassName }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-red-100 bg-white shadow-sm">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-red-100 text-sm">
          <thead className="bg-red-50/70">
            <tr>
              {columns.map((column) => (
                <th key={column.key} className="px-4 py-3 text-left font-bold text-gray-700">
                  {column.label}
                </th>
              ))}
            </tr>
          </thead>

          <tbody className="divide-y divide-red-50">
            {loading ? (
              <tr>
                <td className="px-4 py-6 text-center text-gray-500" colSpan={columns.length}>
                  Carregando dados...
                </td>
              </tr>
            ) : null}

            {!loading && rows.length === 0 ? (
              <tr>
                <td className="px-4 py-6 text-center text-gray-500" colSpan={columns.length}>
                  {emptyMessage}
                </td>
              </tr>
            ) : null}

            {!loading
              ? rows.map((row) => (
                  <tr key={row.id} className={typeof rowClassName === 'function' ? rowClassName(row) : ''}>
                    {columns.map((column) => (
                      <td key={`${row.id}-${column.key}`} className="px-4 py-3 align-middle text-gray-700">
                        {column.render ? column.render(row) : row[column.key]}
                      </td>
                    ))}
                  </tr>
                ))
              : null}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default DataTable
