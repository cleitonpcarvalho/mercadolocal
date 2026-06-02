from __future__ import annotations

import random
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction

from products.models import Category, Product, ProductImage
from stores.models import Store, StoreCategory, StoreCategoryRelation
from users.models import CustomUser

PASSWORD_PADRAO = "Senha@123"
CIDADE = "São Luís"
ESTADO = "MA"

STORE_OWNER_USERS = [
    {"name": "Ana Souza", "email": "loja.modafeminina@mercadolocal.com", "phone": "(98) 98811-1001"},
    {"name": "Carlos Mendes", "email": "loja.calcados@mercadolocal.com", "phone": "(98) 98811-1002"},
    {"name": "Roberto Lima", "email": "loja.eletronicos@mercadolocal.com", "phone": "(98) 98811-1003"},
    {"name": "Fernanda Costa", "email": "loja.perfumaria@mercadolocal.com", "phone": "(98) 98811-1004"},
    {"name": "Marcos Oliveira", "email": "loja.brinquedos@mercadolocal.com", "phone": "(98) 98811-1005"},
    {"name": "João Silva", "email": "loja.pecasmoto@mercadolocal.com", "phone": "(98) 98811-1006"},
    {"name": "Rafael Santos", "email": "loja.suplementos@mercadolocal.com", "phone": "(98) 98811-1007"},
    {"name": "Camila Rocha", "email": "loja.petshop@mercadolocal.com", "phone": "(98) 98811-1008"},
    {"name": "Patricia Alves", "email": "loja.utilidades@mercadolocal.com", "phone": "(98) 98811-1009"},
    {"name": "Diego Ferreira", "email": "loja.esportes@mercadolocal.com", "phone": "(98) 98811-1010"},
]

EXTRA_USERS = [
    {
        "name": "Maria Teste",
        "email": "cliente@mercadolocal.com",
        "phone": "(98) 98822-2001",
        "role": CustomUser.Role.CUSTOMER,
    },
    {
        "name": "Lucas Entregador",
        "email": "entregador@mercadolocal.com",
        "phone": "(98) 98822-2002",
        "role": CustomUser.Role.DELIVERY_DRIVER,
    },
]

STORE_CATEGORY_ICONS = {
    "Loja de Roupas": "shirt",
    "Perfumaria": "spray-can",
    "Loja de Eletrônicos": "smartphone",
    "Loja de Informática": "laptop",
    "Loja de Calçados": "shoe",
    "Loja de Brinquedos": "toy-brick",
    "Peças de Moto": "bike",
    "Peças de Carro": "car",
    "Suplementos": "dumbbell",
    "Pet Shop": "paw-print",
    "Papelaria": "notebook-pen",
    "Loja de Utilidades": "home",
    "Loja de Esportes": "trophy",
    "Loja de Cosméticos": "sparkles",
}

PRODUCT_CATEGORY_TREE = {
    "Roupas Femininas": ("Moda e Vestuário", "shirt", "shirt"),
    "Calçados": ("Moda e Vestuário", "shirt", "shoe"),
    "Acessórios de Celular": ("Eletrônicos e Informática", "cpu", "smartphone"),
    "Perfumes": ("Beleza e Perfumaria", "sparkles", "spray-can"),
    "Brinquedos Infantis": ("Brinquedos e Jogos", "toy-brick", "toy-brick"),
    "Peças de Moto": ("Peças e Acessórios Automotivos", "wrench", "bike"),
    "Suplementos": ("Suplementos e Saúde", "heart-pulse", "dumbbell"),
    "Acessórios para Pets": ("Pet Shop", "paw-print", "paw-print"),
    "Organização": ("Casa e Utilidades", "home", "boxes"),
    "Roupas Esportivas": ("Esporte e Lazer", "trophy", "shirt"),
}

STORE_DATA = [
    {
        "name": "Bella Moda Feminina",
        "owner_email": "loja.modafeminina@mercadolocal.com",
        "description": "Roupas femininas modernas e acessíveis para o dia a dia",
        "address": "Rua do Sol, 145, Centro, São Luís - MA",
        "latitude": Decimal("-2.529870"),
        "longitude": Decimal("-44.295210"),
        "store_category": "Loja de Roupas",
        "product_category": "Roupas Femininas",
        "products": [
            ("Blusa Floral Verão", "49.90"),
            ("Vestido Midi Estampado", "89.90"),
            ("Calça Jeans Skinny", "119.90"),
            ("Shorts Jeans Feminino", "69.90"),
            ("Saia Midi Plissada", "79.90"),
            ("Blusa Cropped Listrada", "39.90"),
            ("Conjunto Fitness Feminino", "99.90"),
            ("Macaquinho Estampado", "89.90"),
            ("Cardigan Tricô", "109.90"),
            ("Top Alcinha", "34.90"),
            ("Legging Suplex", "59.90"),
            ("Blusa Manga Longa", "54.90"),
            ("Vestido Longo Festa", "149.90"),
            ("Conjunto Bermuda e Blusa", "79.90"),
            ("Regata Básica Cotton", "29.90"),
            ("Blusa Social Feminina", "69.90"),
            ("Calça Palazzo", "99.90"),
            ("Shorts de Moletom", "49.90"),
            ("Vestido Casual Verão", "74.90"),
            ("Blusa Tie Dye", "44.90"),
        ],
    },
    {
        "name": "Passo Certo Calçados",
        "owner_email": "loja.calcados@mercadolocal.com",
        "description": "Os melhores calçados masculinos, femininos e infantis",
        "address": "Av. Getúlio Vargas, 320, Centro, São Luís - MA",
        "latitude": Decimal("-2.532340"),
        "longitude": Decimal("-44.289450"),
        "store_category": "Loja de Calçados",
        "product_category": "Calçados",
        "products": [
            ("Tênis Casual Masculino", "159.90"),
            ("Sandália Rasteira Feminina", "79.90"),
            ("Sapato Social Masculino", "189.90"),
            ("Chinelo de Dedo", "39.90"),
            ("Tênis Feminino Colorido", "139.90"),
            ("Bota Couro Masculina", "299.90"),
            ("Sapatilha Feminina", "89.90"),
            ("Tênis Infantil", "109.90"),
            ("Sandália Plataforma", "119.90"),
            ("Mocassim Masculino", "169.90"),
            ("Tênis Running Feminino", "179.90"),
            ("Chuteira Society", "129.90"),
            ("Sandália Masculina", "69.90"),
            ("Scarpin Salto Fino", "149.90"),
            ("Bota Feminina Cano Curto", "219.90"),
            ("Chinelo Nuvem", "59.90"),
            ("Sapato Feminino Oxford", "139.90"),
            ("Tênis Skate", "149.90"),
            ("Sandália Conforto", "99.90"),
            ("Bota Coturno", "249.90"),
        ],
    },
    {
        "name": "TechZone Eletrônicos",
        "owner_email": "loja.eletronicos@mercadolocal.com",
        "description": "Acessórios para celular, informática e muito mais",
        "address": "Rua Grande, 78, Centro, São Luís - MA",
        "latitude": Decimal("-2.530110"),
        "longitude": Decimal("-44.286780"),
        "store_category": "Loja de Eletrônicos",
        "product_category": "Acessórios de Celular",
        "products": [
            ("Capinha iPhone 14", "34.90"),
            ("Carregador Turbo USB-C", "49.90"),
            ("Fone Bluetooth", "129.90"),
            ("Película 3D", "19.90"),
            ("Suporte Veicular Celular", "39.90"),
            ("Cabo USB-C 2m", "24.90"),
            ("Powerbank 10000mAh", "119.90"),
            ("Capinha Samsung S23", "34.90"),
            ("Mouse Sem Fio", "89.90"),
            ("Teclado Bluetooth", "149.90"),
            ("Hub USB 4 Portas", "69.90"),
            ("Suporte Notebook", "99.90"),
            ("Webcam HD", "179.90"),
            ("Headset Gamer", "199.90"),
            ("Mousepad Gamer XL", "59.90"),
            ("Adaptador HDMI", "29.90"),
            ("Caixa de Som Bluetooth", "119.90"),
            ("Smartwatch Básico", "249.90"),
            ("Capinha Xiaomi Redmi", "29.90"),
            ("Carregador Wireless", "79.90"),
        ],
    },
    {
        "name": "Essence Perfumaria",
        "owner_email": "loja.perfumaria@mercadolocal.com",
        "description": "Perfumes nacionais e importados com os melhores preços",
        "address": "Shopping da Ilha, Loja 34, São Luís - MA",
        "latitude": Decimal("-2.538950"),
        "longitude": Decimal("-44.274220"),
        "store_category": "Perfumaria",
        "product_category": "Perfumes",
        "products": [
            ("Perfume Masculino 100ml", "189.90"),
            ("Perfume Feminino Floral 75ml", "159.90"),
            ("Body Splash Tropical", "49.90"),
            ("Perfume Árabe Oud 50ml", "219.90"),
            ("Colônia Masculina", "89.90"),
            ("Perfume Feminino Oriental", "179.90"),
            ("Kit Perfume e Hidratante", "129.90"),
            ("Body Mist Frutado", "44.90"),
            ("Perfume Importado 100ml", "349.90"),
            ("Desodorante Colônia", "69.90"),
            ("Eau de Toilette Feminino", "139.90"),
            ("Perfume Masculino Sport", "149.90"),
            ("Óleo Perfumado", "59.90"),
            ("Perfume Unissex", "199.90"),
            ("Body Splash Masculino", "54.90"),
            ("Perfume Infantil", "79.90"),
            ("Kit Body Splash 3 Aromas", "99.90"),
            ("Perfume Feminino Gourmand", "169.90"),
            ("Hidratante Perfumado", "74.90"),
            ("Perfume Masculino Fresh", "159.90"),
        ],
    },
    {
        "name": "Mundo Kids Brinquedos",
        "owner_email": "loja.brinquedos@mercadolocal.com",
        "description": "Brinquedos educativos e diversão para todas as idades",
        "address": "Rua Oswaldo Cruz, 210, Centro, São Luís - MA",
        "latitude": Decimal("-2.528760"),
        "longitude": Decimal("-44.292130"),
        "store_category": "Loja de Brinquedos",
        "product_category": "Brinquedos Infantis",
        "products": [
            ("Boneca Articulada", "79.90"),
            ("Carrinho Hot Wheels Kit", "49.90"),
            ("Jogo de Montar 100 Peças", "89.90"),
            ("Pelúcia Urso Grande", "99.90"),
            ("Pista de Carrinhos", "139.90"),
            ("Massinha de Modelar", "29.90"),
            ("Kit Pintura Infantil", "54.90"),
            ("Quebra-Cabeça 200 Peças", "44.90"),
            ("Bola de Futebol Infantil", "59.90"),
            ("Skate Infantil", "119.90"),
            ("Jogo de Damas", "34.90"),
            ("Boneca de Pano", "69.90"),
            ("Carrinho de Controle Remoto", "149.90"),
            ("Kit Ciência Infantil", "89.90"),
            ("Lego Básico 50 Peças", "79.90"),
            ("Pular Corda", "24.90"),
            ("Jogo da Memória", "39.90"),
            ("Pelúcia Dinossauro", "84.90"),
            ("Brinquedo de Encaixe", "49.90"),
            ("Jogo Uno", "29.90"),
        ],
    },
    {
        "name": "MotoCenter Peças",
        "owner_email": "loja.pecasmoto@mercadolocal.com",
        "description": "Peças e acessórios para motos de todas as marcas",
        "address": "Av. dos Holandeses, 890, Calhau, São Luís - MA",
        "latitude": Decimal("-2.507980"),
        "longitude": Decimal("-44.265430"),
        "store_category": "Peças de Moto",
        "product_category": "Peças de Moto",
        "products": [
            ("Capacete Aberto Masculino", "189.90"),
            ("Luva Moto Couro", "89.90"),
            ("Retrovisor Universal", "34.90"),
            ("Corrente Moto 428", "79.90"),
            ("Pneu Traseiro 90/90", "219.90"),
            ("Pastilha de Freio", "49.90"),
            ("Óleo Motor 4T", "39.90"),
            ("Jogo de Cabo Freio", "29.90"),
            ("Pisca LED Universal", "44.90"),
            ("Manete Esportivo", "54.90"),
            ("Banco Moto Personalizado", "149.90"),
            ("Alarme Moto", "119.90"),
            ("Suporte Baú Traseiro", "89.90"),
            ("Kit Relação Completo", "199.90"),
            ("Pneu Dianteiro 80/100", "189.90"),
            ("Lanterna LED Moto", "64.90"),
            ("Protetor de Motor", "179.90"),
            ("Capacete Fechado", "299.90"),
            ("Guidão Esportivo", "129.90"),
            ("Espelho Esportivo Par", "49.90"),
        ],
    },
    {
        "name": "Force Suplementos",
        "owner_email": "loja.suplementos@mercadolocal.com",
        "description": "Suplementos alimentares e vitaminas para sua performance",
        "address": "Rua da Paz, 55, Renascença, São Luís - MA",
        "latitude": Decimal("-2.503670"),
        "longitude": Decimal("-44.281950"),
        "store_category": "Suplementos",
        "product_category": "Suplementos",
        "products": [
            ("Whey Protein 1kg", "129.90"),
            ("Creatina 300g", "89.90"),
            ("BCAA 100 Cápsulas", "69.90"),
            ("Pré-Treino 300g", "99.90"),
            ("Vitamina C 1000mg", "39.90"),
            ("Multivitamínico 60 Cápsulas", "59.90"),
            ("Ômega 3 60 Cápsulas", "49.90"),
            ("Albumina 500g", "79.90"),
            ("Hipercalórico 3kg", "189.90"),
            ("Glutamina 300g", "89.90"),
            ("Coqueteleira 700ml", "34.90"),
            ("Luva de Academia", "44.90"),
            ("Barra de Proteína Caixa", "79.90"),
            ("Termogênico 60 Cápsulas", "69.90"),
            ("Colágeno Hidrolisado", "54.90"),
            ("Whey Protein 2kg", "229.90"),
            ("Maltodextrina 1kg", "49.90"),
            ("Cinta Abdominal", "89.90"),
            ("Vitamina D3", "44.90"),
            ("ZMA 90 Cápsulas", "59.90"),
        ],
    },
    {
        "name": "PetAmor Shop",
        "owner_email": "loja.petshop@mercadolocal.com",
        "description": "Tudo para o seu pet com amor e qualidade",
        "address": "Rua São Pantaleão, 430, Centro, São Luís - MA",
        "latitude": Decimal("-2.536420"),
        "longitude": Decimal("-44.291540"),
        "store_category": "Pet Shop",
        "product_category": "Acessórios para Pets",
        "products": [
            ("Coleira Regulável Cão", "29.90"),
            ("Ração Golden Adulto 3kg", "89.90"),
            ("Cama Pet Tamanho M", "99.90"),
            ("Brinquedo Mordedor", "24.90"),
            ("Arranhador Gato", "79.90"),
            ("Shampoo Pet 500ml", "34.90"),
            ("Guia Retrátil 5m", "49.90"),
            ("Comedouro Inox", "39.90"),
            ("Bebedouro Automático", "69.90"),
            ("Casinha Pet Tamanho M", "149.90"),
            ("Tapete Higiênico 30un", "44.90"),
            ("Antipulgas Coleira", "54.90"),
            ("Brinquedo Interativo Gato", "34.90"),
            ("Sacola Transporte Pet", "119.90"),
            ("Ração Gato Whiskas 3kg", "79.90"),
            ("Pente Duplo Pet", "19.90"),
            ("Roupinha Pet Tamanho P", "44.90"),
            ("Osso para Cão", "14.90"),
            ("Caixa Transporte Gato", "129.90"),
            ("Areia Higiênica 4kg", "39.90"),
        ],
    },
    {
        "name": "Casa & Cia Utilidades",
        "owner_email": "loja.utilidades@mercadolocal.com",
        "description": "Utilidades domésticas, organização e decoração para sua casa",
        "address": "Av. Litorânea, 1200, Calhau, São Luís - MA",
        "latitude": Decimal("-2.505910"),
        "longitude": Decimal("-44.249870"),
        "store_category": "Loja de Utilidades",
        "product_category": "Organização",
        "products": [
            ("Organizador Gaveta 6 Peças", "49.90"),
            ("Cabide Veludo 10un", "29.90"),
            ("Porta Temperos Giratório", "59.90"),
            ("Jogo de Potes Herméticos", "69.90"),
            ("Escorredor de Louça", "79.90"),
            ("Cesto Roupa Suja", "54.90"),
            ("Saboneteira Dispenser", "34.90"),
            ("Tapete Banheiro Antiderrapante", "39.90"),
            ("Suporte Papel Toalha", "29.90"),
            ("Lixeira Pedal 12L", "69.90"),
            ("Jogo de Toalhas 4 Peças", "89.90"),
            ("Porta Shampoo Aramado", "44.90"),
            ("Cabideiro Parede", "54.90"),
            ("Organizador Mala Viagem", "64.90"),
            ("Jogo Xícaras 6 Peças", "79.90"),
            ("Porta Bijoux", "49.90"),
            ("Caixa Organizadora Tampa", "39.90"),
            ("Vassoura e Recogedor", "34.90"),
            ("Toalha de Mesa 6 Lugares", "89.90"),
            ("Kit Limpeza 5 Peças", "59.90"),
        ],
    },
    {
        "name": "SportMax Esportes",
        "owner_email": "loja.esportes@mercadolocal.com",
        "description": "Roupas esportivas e equipamentos para todos os esportes",
        "address": "Rua Rui Barbosa, 340, Centro, São Luís - MA",
        "latitude": Decimal("-2.531980"),
        "longitude": Decimal("-44.290220"),
        "store_category": "Loja de Esportes",
        "product_category": "Roupas Esportivas",
        "products": [
            ("Camiseta Dry-Fit Masculina", "59.90"),
            ("Shorts Tactel", "49.90"),
            ("Tênis Academia", "169.90"),
            ("Legging Academia Feminina", "79.90"),
            ("Meia Esportiva Kit 3 Pares", "34.90"),
            ("Regata Masculina", "44.90"),
            ("Top Fitness", "54.90"),
            ("Calça Jogger", "99.90"),
            ("Jaqueta Corta Vento", "139.90"),
            ("Bermuda Ciclismo", "89.90"),
            ("Raquete Beach Tennis", "149.90"),
            ("Bola Vôlei Oficial", "99.90"),
            ("Corda de Pular Speed", "39.90"),
            ("Luva Boxe Iniciante", "119.90"),
            ("Caneleira 2kg Par", "54.90"),
            ("Faixa Abdominal", "44.90"),
            ("Pochete Esportiva", "34.90"),
            ("Óculos Natação", "49.90"),
            ("Toalha Esportiva Microfibra", "54.90"),
            ("Squeeze 700ml", "29.90"),
        ],
    },
]


class Command(BaseCommand):
    help = "Cria dados fake realistas do Mercado Local para testes locais."

    def _create_user(
        self,
        *,
        name: str,
        email: str,
        phone: str,
        role: str,
        password: str,
    ) -> CustomUser:
        user = CustomUser.objects.create_user(
            username=email,
            email=email,
            password=password,
            first_name=name,
            role=role,
            phone=phone,
            city=CIDADE,
            state=ESTADO,
            is_active=True,
            is_verified=False,
        )
        return user

    def _ensure_store_category(self, name: str) -> StoreCategory:
        icon = STORE_CATEGORY_ICONS.get(name, "store")
        category, _ = StoreCategory.objects.get_or_create(name=name, defaults={"icon": icon})
        if not category.icon:
            category.icon = icon
            category.save(update_fields=["icon"])
        return category

    def _ensure_product_category(self, child_name: str) -> Category:
        root_name, root_icon, child_icon = PRODUCT_CATEGORY_TREE[child_name]

        root_category, _ = Category.objects.get_or_create(
            name=root_name,
            defaults={"icon": root_icon, "parent": None},
        )
        if not root_category.icon:
            root_category.icon = root_icon
            root_category.save(update_fields=["icon"])

        child_category, _ = Category.objects.get_or_create(
            name=child_name,
            defaults={"icon": child_icon, "parent": root_category},
        )

        update_fields: list[str] = []
        if child_category.parent_id != root_category.id:
            child_category.parent = root_category
            update_fields.append("parent")
        if not child_category.icon:
            child_category.icon = child_icon
            update_fields.append("icon")
        if update_fields:
            child_category.save(update_fields=update_fields)

        return child_category

    @transaction.atomic
    def handle(self, *args, **options):
        rng = random.Random(20260423)

        removed_users, _ = CustomUser.objects.filter(email__iendswith="@mercadolocal.com").delete()
        if removed_users:
            self.stdout.write(
                self.style.WARNING(
                    f"Dados antigos removidos antes do seed: {removed_users} registros em cascata."
                )
            )

        users_by_email: dict[str, CustomUser] = {}
        created_users = 0
        created_stores = 0
        created_products = 0
        created_images = 0

        for owner in STORE_OWNER_USERS:
            user = self._create_user(
                name=owner["name"],
                email=owner["email"],
                phone=owner["phone"],
                role=CustomUser.Role.STORE_OWNER,
                password=PASSWORD_PADRAO,
            )
            users_by_email[user.email] = user
            created_users += 1

        for extra in EXTRA_USERS:
            user = self._create_user(
                name=extra["name"],
                email=extra["email"],
                phone=extra["phone"],
                role=extra["role"],
                password=PASSWORD_PADRAO,
            )
            users_by_email[user.email] = user
            created_users += 1

        image_counter = 100

        for store_payload in STORE_DATA:
            owner = users_by_email[store_payload["owner_email"]]
            store = Store.objects.create(
                owner=owner,
                name=store_payload["name"],
                description=store_payload["description"],
                logo=f"https://picsum.photos/200/200?random={image_counter}",
                phone=owner.phone,
                city=CIDADE,
                state=ESTADO,
                address=store_payload["address"],
                latitude=store_payload["latitude"],
                longitude=store_payload["longitude"],
                is_active=True,
                is_verified=True,
                commission_rate=Decimal("10.00"),
            )
            created_stores += 1
            image_counter += 1

            store_category = self._ensure_store_category(store_payload["store_category"])
            StoreCategoryRelation.objects.create(store=store, category=store_category)

            product_category = self._ensure_product_category(store_payload["product_category"])

            for index, (product_name, product_price) in enumerate(store_payload["products"], start=1):
                condition = Product.Condition.NEW if index % 2 != 0 else Product.Condition.USED
                is_featured = index % 4 == 0
                stock = rng.randint(5, 50)
                weight = Decimal(str(round(rng.uniform(0.1, 2.0), 3)))

                product = Product.objects.create(
                    store=store,
                    category=product_category,
                    name=product_name,
                    description=(
                        f"{product_name} da loja {store.name}. "
                        "Produto com envio rápido em São Luís e qualidade garantida."
                    ),
                    price=Decimal(product_price),
                    stock=stock,
                    condition=condition,
                    weight_kg=weight,
                    is_available=True,
                    is_featured=is_featured,
                    pickup_only=False,
                )
                created_products += 1

                ProductImage.objects.create(
                    product=product,
                    image=f"https://picsum.photos/400/400?random={image_counter}",
                    order=0,
                )
                created_images += 1
                image_counter += 1

        self.stdout.write(self.style.SUCCESS("Seed fake concluído com sucesso."))
        self.stdout.write(self.style.SUCCESS(f"Total users created: {created_users}"))
        self.stdout.write(self.style.SUCCESS(f"Total stores created: {created_stores}"))
        self.stdout.write(self.style.SUCCESS(f"Total products created: {created_products}"))
        self.stdout.write(self.style.SUCCESS(f"Total product images created: {created_images}"))
