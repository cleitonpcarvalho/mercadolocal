function StatCard({ label, value, highlight = false }) {
  return (
    <article
      className={`rounded-2xl border p-4 shadow-sm ${
        highlight ? 'border-primary bg-red-50/60' : 'border-red-100 bg-white'
      }`}
    >
      <p className="text-sm font-medium text-gray-500">{label}</p>
      <p className="mt-2 text-3xl font-black text-gray-900">{value}</p>
    </article>
  )
}

export default StatCard
