# Mercado Local

Estrutura inicial do projeto hyperlocal marketplace **Mercado Local** com:

- `backend`: Django + DRF + Docker
- `frontend`: React (Vite) + Tailwind CSS + Leaflet/OpenStreetMap
- `appclient`: app Flutter para clientes
- `appdelivery`: app Flutter para entregadores

## Estrutura

```text
AppMercadoLocal/
├── backend/
│   ├── core/
│   │   ├── __init__.py
│   │   ├── asgi.py
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── .env
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── manage.py
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── assets/logos/
│   │   ├── components/
│   │   ├── context/
│   │   ├── hooks/
│   │   ├── pages/
│   │   └── services/
│   ├── .env
│   ├── Dockerfile
│   ├── tailwind.config.js
│   └── ... (estrutura padrão do Vite)
├── appclient/
│   ├── assets/logos/
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── utils/
│   │   └── widgets/
│   └── ... (estrutura padrão Flutter)
└── appdelivery/
    ├── assets/logos/
    ├── lib/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   ├── utils/
    │   └── widgets/
    └── ... (estrutura padrão Flutter)
```

## Observações iniciais

- Nenhum servidor foi iniciado.
- Nenhuma migration foi executada.
- Backend preparado para usar PostgreSQL via `DATABASE_URL` e autenticação JWT.
- Frontend preparado com Tailwind e dependências de mapa (`leaflet`, `react-leaflet`).
- Apps Flutter configurados com `flutter_map` e `latlong2`.
