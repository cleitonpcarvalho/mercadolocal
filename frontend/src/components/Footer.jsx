function Footer() {
  return (
    <footer className="mt-14 border-t border-red-100 bg-white">
      <div className="mx-auto grid max-w-7xl gap-4 px-4 py-8 text-sm text-gray-600 md:grid-cols-2 md:px-6">
        <div>
          <p className="text-base font-bold text-gray-900">Mercado Local</p>
          <p className="mt-2">Shopping local para comprar perto de você.</p>
        </div>
        <div className="flex gap-4 md:justify-end">
          <a className="hover:text-primary" href="#">
            Termos
          </a>
          <a className="hover:text-primary" href="#">
            Privacidade
          </a>
          <a className="hover:text-primary" href="#">
            Suporte
          </a>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
