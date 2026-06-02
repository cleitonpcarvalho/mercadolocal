# Mercado Local

**Mercado Local** é uma plataforma de marketplace hiperlocal criada para conectar clientes, lojistas e entregadores em uma experiência única de compra, gestão e entrega. O projeto organiza backend, painéis web e aplicativos mobile em um monorepo, facilitando a evolução do produto, a manutenção técnica e a integração entre os módulos.

## Visão Geral

O objetivo do Mercado Local é permitir que comércios locais vendam produtos online com controle operacional completo: cadastro de lojas e produtos, carrinho, pedidos, entregas, anúncios, painel administrativo e aplicativos dedicados para clientes e entregadores.

O repositório está dividido em cinco frentes principais:

- **Backend API**: Django + Django REST Framework com autenticação JWT, PostgreSQL e suporte opcional a armazenamento S3/Supabase.
- **Frontend web**: aplicação React para clientes e lojistas, com experiência de compra, busca, loja, carrinho, pedidos e painel do estabelecimento.
- **Admin web**: painel administrativo para acompanhamento de usuários, lojas, produtos, pedidos, entregas, anúncios e indicadores.
- **App cliente**: aplicativo Flutter para compra local, navegação por lojas/produtos, carrinho, pedidos e perfil.
- **App entregador**: aplicativo Flutter para entregadores acompanharem entregas disponíveis, histórico, status e localização.

## Principais Recursos

- Autenticação por JWT com refresh token e logout com blacklist.
- Cadastro de usuários com perfis de cliente, lojista, entregador e administrador.
- Gestão de lojas, categorias de lojas, produtos, imagens e categorias de produtos.
- Fluxo de pedidos com itens, pagamento, status e acompanhamento.
- Fluxo de entregas com aceite, atualização de status e localização do entregador.
- Anúncios do tipo banner, produto em destaque e loja patrocinada.
- Dashboard operacional para métricas e visão administrativa.
- Interfaces web responsivas com React, Vite, Tailwind CSS e componentes reutilizáveis.
- Aplicativos mobile em Flutter com armazenamento seguro, mapas, imagens em cache e notificações Firebase.

## Stack Técnica

| Camada | Tecnologias |
| --- | --- |
| Backend | Python 3.11+, Django 5.2, Django REST Framework, Simple JWT, Gunicorn |
| Banco de dados | PostgreSQL via `DATABASE_URL` |
| Storage opcional | Supabase Storage/S3-compatible via `django-storages` e `boto3` |
| Frontend | React 19, Vite, Tailwind CSS, React Router, React Query, Axios, Zustand |
| Mapas | Leaflet, React Leaflet, OpenStreetMap, `flutter_map`, `latlong2` |
| Admin | React 19, Vite, Tailwind CSS, Recharts, Lucide Icons |
| Mobile | Flutter, Provider, GoRouter, Dio, Flutter Secure Storage, Firebase Messaging |
| DevOps | Dockerfile e Docker Compose para o backend |

## Estrutura do Repositório

```text
AppMercadoLocal/
├── backend/       # API Django, modelos, serializers, viewsets e comandos de seed
├── frontend/      # Web app para clientes e lojistas
├── admin/         # Painel administrativo da plataforma
├── appclient/     # App Flutter para clientes
├── appdelivery/   # App Flutter para entregadores
├── .gitignore     # Regras globais de versionamento
└── README.md      # Documentação principal do projeto
```

## Requisitos

Antes de executar o projeto localmente, garanta que o ambiente tenha:

- Git
- Python 3.11+
- Poetry
- PostgreSQL local ou remoto
- Node.js LTS e npm
- Flutter SDK com Dart compatível com os apps
- Docker e Docker Compose, caso prefira rodar o backend em container

## Configuração de Ambiente

Arquivos `.env` não são versionados por segurança. Crie os arquivos locais conforme necessário.

### Backend

Crie `backend/.env`:

```env
SECRET_KEY=troque-esta-chave
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres

CORS_ALLOW_ALL_ORIGINS=False
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5180,http://localhost:5181
CSRF_TRUSTED_ORIGINS=http://localhost:5173,http://localhost:5180,http://localhost:5181

SUPABASE_URL=
SUPABASE_STORAGE_BUCKET=
SUPABASE_PUBLISHABLE_KEY=
```

As variáveis de Supabase são opcionais e devem ser preenchidas apenas quando o storage remoto estiver configurado.

### Frontend Web

Crie `frontend/.env`:

```env
VITE_API_URL=http://localhost:8001
```

O cliente web adiciona `/api` automaticamente quando a URL base não termina com esse sufixo.

### Apps Flutter

Os apps usam `http://localhost:8001` como URL base durante o desenvolvimento local:

- `appclient/lib/core/constants/api_constants.dart`
- `appdelivery/lib/core/constants/api_constants.dart`

Para emuladores Android, dispositivos físicos ou ambiente de rede, ajuste `ApiConstants.baseUrl` para o host acessível pela aplicação.

## Como Executar

### Backend com Poetry

```bash
cd backend
poetry install
poetry run python manage.py migrate
poetry run python manage.py runserver 0.0.0.0:8001
```

Comandos opcionais de carga inicial:

```bash
poetry run python manage.py seed_store_categories
poetry run python manage.py seed_categories
poetry run python manage.py seed_fake_data
```

### Backend com Docker

```bash
cd backend
docker compose up --build
```

O serviço expõe a API em `http://localhost:8001`. O PostgreSQL deve estar acessível pela `DATABASE_URL` definida no `.env`.

### Frontend Web

```bash
cd frontend
npm install
npm run dev -- --port 5173
```

A aplicação fica disponível em `http://localhost:5173`.

### Painel Admin

```bash
cd admin
npm install
npm run dev -- --port 5180
```

O painel fica disponível em `http://localhost:5180`.

### App Cliente

```bash
cd appclient
flutter pub get
flutter run
```

### App Entregador

```bash
cd appdelivery
flutter pub get
flutter run
```

## Rotas Principais da API

A API é servida a partir de `http://localhost:8001/api/`.

| Recurso | Base URL |
| --- | --- |
| Usuários e autenticação | `/api/users/` |
| Lojas | `/api/stores/` |
| Categorias de lojas | `/api/stores/categories/` |
| Produtos | `/api/products/` |
| Categorias de produtos | `/api/products/categories/` |
| Pedidos | `/api/orders/` |
| Entregas | `/api/deliveries/` |
| Entregas disponíveis | `/api/deliveries/available/` |
| Anúncios | `/api/ads/` |
| Anúncios ativos | `/api/ads/active/` |
| Dashboard | `/api/dashboard/` |

O painel administrativo nativo do Django fica em `http://localhost:8001/admin/`.

## Comandos Úteis

### Backend

```bash
cd backend
poetry run python manage.py check
poetry run python manage.py makemigrations
poetry run python manage.py migrate
poetry run python manage.py createsuperuser
poetry run black .
poetry run isort .
poetry run flake8
```

### Frontend e Admin

```bash
npm run lint
npm run build
npm run preview
```

### Flutter

```bash
flutter analyze
flutter test
flutter build apk
```

## Boas Práticas de Versionamento

- Não versionar `.env`, credenciais, bancos locais, builds ou dependências instaladas.
- Manter `node_modules/`, `.dart_tool/`, `build/`, `Pods/`, `staticfiles/`, `media/` e `db.sqlite3` fora do Git.
- Registrar mudanças relevantes em commits pequenos e descritivos.
- Rodar checks locais antes de publicar alterações importantes.

## Status do Projeto

O Mercado Local está estruturado como uma base full stack em evolução, com API, interfaces web e apps mobile prontos para desenvolvimento incremental. A arquitetura atual favorece expansão por módulos, integração com serviços externos e amadurecimento do produto para ambientes de homologação e produção.
