# Pierwsza migracja tworzy tabele zgłoszeń i komentarzy.

import uuid

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Ticket",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("title", models.CharField(max_length=200, verbose_name="Tytuł")),
                ("description", models.TextField(verbose_name="Opis")),
                ("requester_email", models.EmailField(max_length=254, verbose_name="E-mail zgłaszającego")),
                ("priority", models.CharField(choices=[("low", "Niski"), ("medium", "Średni"), ("high", "Wysoki"), ("urgent", "Pilny")], default="medium", max_length=16, verbose_name="Priorytet")),
                ("status", models.CharField(choices=[("new", "Nowe"), ("in_progress", "W realizacji"), ("resolved", "Rozwiązane"), ("closed", "Zamknięte")], default="new", max_length=16, verbose_name="Status")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Utworzono")),
                ("updated_at", models.DateTimeField(auto_now=True, verbose_name="Zaktualizowano")),
                ("assigned_to", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL, verbose_name="Przypisany operator")),
            ],
            options={
                "verbose_name": "Zgłoszenie",
                "verbose_name_plural": "Zgłoszenia",
                "ordering": ["-created_at"],
            },
        ),
        migrations.CreateModel(
            name="Comment",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("text", models.TextField(verbose_name="Treść")),
                ("created_at", models.DateTimeField(auto_now_add=True, verbose_name="Utworzono")),
                ("author", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL, verbose_name="Autor")),
                ("ticket", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="comments", to="tickets.ticket", verbose_name="Zgłoszenie")),
            ],
            options={
                "verbose_name": "Komentarz",
                "verbose_name_plural": "Komentarze",
                "ordering": ["created_at"],
            },
        ),
    ]