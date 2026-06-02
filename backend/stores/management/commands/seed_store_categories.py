from django.core.management.base import BaseCommand
from django.db import transaction

from stores.models import StoreCategory


STORE_CATEGORIES = [
    ("Loja de Roupas", "shirt"),
    ("Perfumaria", "spray-can"),
    ("Loja de Eletrônicos", "smartphone"),
    ("Loja de Informática", "laptop"),
    ("Loja de Calçados", "shoe"),
    ("Loja de Brinquedos", "toy-brick"),
    ("Peças de Moto", "bike"),
    ("Peças de Carro", "car"),
    ("Suplementos", "dumbbell"),
    ("Pet Shop", "paw-print"),
    ("Papelaria", "notebook-pen"),
    ("Loja de Utilidades", "home"),
    ("Loja de Esportes", "trophy"),
    ("Loja de Cosméticos", "sparkles"),
]


class Command(BaseCommand):
    help = "Seeds store categories for Mercado Local."

    @transaction.atomic
    def handle(self, *args, **options):
        deleted_count, _ = StoreCategory.objects.all().delete()

        for name, icon in STORE_CATEGORIES:
            StoreCategory.objects.create(name=name, icon=icon)

        self.stdout.write(
            self.style.SUCCESS(
                "Store categories seeded successfully. "
                f"Removed: {deleted_count}, Created: {len(STORE_CATEGORIES)}."
            )
        )
