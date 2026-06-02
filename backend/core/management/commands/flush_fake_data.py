from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from users.models import CustomUser


class Command(BaseCommand):
    help = "Remove apenas dados fake criados pelo seed_fake_data (domínio @mercadolocal.com)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--confirm",
            action="store_true",
            help="Confirma a remoção dos dados fake.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if not options["confirm"]:
            raise CommandError(
                "Operação bloqueada por segurança. Use: python manage.py flush_fake_data --confirm"
            )

        users_qs = CustomUser.objects.filter(email__iendswith="@mercadolocal.com")
        users_count = users_qs.count()

        if users_count == 0:
            self.stdout.write(self.style.WARNING("Nenhum dado fake encontrado para remoção."))
            return

        deleted_total, deleted_map = users_qs.delete()

        self.stdout.write(self.style.SUCCESS("Dados fake removidos com sucesso."))
        self.stdout.write(self.style.SUCCESS(f"Usuários removidos: {users_count}"))
        self.stdout.write(self.style.SUCCESS(f"Registros removidos em cascata: {deleted_total}"))

        if deleted_map:
            breakdown = ", ".join(f"{model}: {count}" for model, count in sorted(deleted_map.items()))
            self.stdout.write(self.style.WARNING(f"Detalhamento: {breakdown}"))
