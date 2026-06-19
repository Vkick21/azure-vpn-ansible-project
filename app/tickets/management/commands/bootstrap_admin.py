"""Tworzy pierwsze konto operatora bez zapisywania hasła w repozytorium."""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from helpdesk.settings import get_secret


class Command(BaseCommand):
    help = "Tworzy konto admin, jeśli jeszcze nie istnieje."

    def handle(self, *args, **options):
        user_model = get_user_model()
        user, created = user_model.objects.get_or_create(
            username="helpdesk-admin",
            defaults={
                "email": "admin@helpdesk.local",
                "is_staff": True,
                "is_superuser": True,
            },
        )

        if not created:
            self.stdout.write("EXISTS")
            return

        user.set_password(get_secret("django-admin-password", "DJANGO_ADMIN_PASSWORD"))
        user.save(update_fields=["password"])
        self.stdout.write("CREATED")