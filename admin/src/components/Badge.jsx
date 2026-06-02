const variants = {
  gray: 'bg-gray-100 text-gray-700',
  green: 'bg-emerald-100 text-emerald-700',
  red: 'bg-red-100 text-red-700',
  amber: 'bg-amber-100 text-amber-700',
  blue: 'bg-blue-100 text-blue-700',
  purple: 'bg-purple-100 text-purple-700',
}

function Badge({ children, variant = 'gray' }) {
  return (
    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${variants[variant] || variants.gray}`}>
      {children}
    </span>
  )
}

export default Badge
