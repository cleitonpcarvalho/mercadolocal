from django.core.management.base import BaseCommand
from django.db import transaction

from products.models import Category


PRODUCT_CATEGORIES = [
    {
        "name": "Moda e Vestuário",
        "icon": "shirt",
        "subcategories": [
            ("Roupas Masculinas", "shirt"),
            ("Roupas Femininas", "shirt"),
            ("Calçados", "shoe"),
            ("Acessórios de Moda", "gem"),
        ],
    },
    {
        "name": "Beleza e Perfumaria",
        "icon": "sparkles",
        "subcategories": [
            ("Perfumes", "spray-can"),
            ("Cosméticos", "sparkles"),
            ("Cuidados Pessoais", "heart"),
        ],
    },
    {
        "name": "Eletrônicos e Informática",
        "icon": "cpu",
        "subcategories": [
            ("Acessórios de Celular", "smartphone"),
            ("Acessórios de Informática", "laptop"),
            ("Cabos e Carregadores", "plug"),
            ("Fones de Ouvido", "headphones"),
        ],
    },
    {
        "name": "Casa e Utilidades",
        "icon": "home",
        "subcategories": [
            ("Organização", "boxes"),
            ("Decoração", "lamp"),
            ("Limpeza", "spray-bottle"),
            ("Cozinha", "utensils"),
        ],
    },
    {
        "name": "Brinquedos e Jogos",
        "icon": "toy-brick",
        "subcategories": [
            ("Brinquedos Infantis", "toy-brick"),
            ("Jogos de Tabuleiro", "dice-5"),
            ("Colecionáveis", "star"),
        ],
    },
    {
        "name": "Peças e Acessórios Automotivos",
        "icon": "wrench",
        "subcategories": [
            ("Peças de Moto", "bike"),
            ("Peças de Carro", "car"),
            ("Acessórios Automotivos", "wrench"),
        ],
    },
    {
        "name": "Suplementos e Saúde",
        "icon": "heart-pulse",
        "subcategories": [
            ("Suplementos", "dumbbell"),
            ("Vitaminas", "pill"),
            ("Equipamentos de Academia", "dumbbell"),
        ],
    },
    {
        "name": "Papelaria e Escritório",
        "icon": "notebook-pen",
        "subcategories": [
            ("Papelaria", "notebook-pen"),
            ("Material Escolar", "book-open"),
            ("Escritório", "briefcase"),
        ],
    },
    {
        "name": "Pet Shop",
        "icon": "paw-print",
        "subcategories": [
            ("Acessórios para Pets", "paw-print"),
            ("Higiene Pet", "bath"),
        ],
    },
    {
        "name": "Esporte e Lazer",
        "icon": "trophy",
        "subcategories": [
            ("Roupas Esportivas", "shirt"),
            ("Equipamentos Esportivos", "dumbbell"),
            ("Acessórios Esportivos", "medal"),
        ],
    },
]


class Command(BaseCommand):
    help = "Seeds product categories and subcategories for Mercado Local."

    @transaction.atomic
    def handle(self, *args, **options):
        deleted_count, _ = Category.objects.all().delete()

        created_roots = 0
        created_children = 0

        for root_data in PRODUCT_CATEGORIES:
            root = Category.objects.create(
                name=root_data["name"],
                icon=root_data["icon"],
            )
            created_roots += 1

            for child_name, child_icon in root_data["subcategories"]:
                Category.objects.create(
                    name=child_name,
                    icon=child_icon,
                    parent=root,
                )
                created_children += 1

        self.stdout.write(
            self.style.SUCCESS(
                "Product categories seeded successfully. "
                f"Removed: {deleted_count}, "
                f"Created roots: {created_roots}, "
                f"Created subcategories: {created_children}."
            )
        )
