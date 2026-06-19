"""Modele przechowujące zgłoszenia i ich historię."""

import uuid

from django.contrib.auth.models import User
from django.db import models


class Ticket(models.Model):
    class Priority(models.TextChoices):
        LOW = "low", "Niski"
        MEDIUM = "medium", "Średni"
        HIGH = "high", "Wysoki"
        URGENT = "urgent", "Pilny"

    class Status(models.TextChoices):
        NEW = "new", "Nowe"
        IN_PROGRESS = "in_progress", "W realizacji"
        RESOLVED = "resolved", "Rozwiązane"
        CLOSED = "closed", "Zamknięte"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField("Tytuł", max_length=200)
    description = models.TextField("Opis")
    attachment = models.FileField("Załącznik", upload_to="tickets/%Y/%m/", blank=True)
    requester_email = models.EmailField("E-mail zgłaszającego")
    priority = models.CharField(
        "Priorytet",
        max_length=16,
        choices=Priority.choices,
        default=Priority.MEDIUM,
    )
    status = models.CharField(
        "Status",
        max_length=16,
        choices=Status.choices,
        default=Status.NEW,
    )
    assigned_to = models.ForeignKey(
        User,
        verbose_name="Przypisany operator",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField("Utworzono", auto_now_add=True)
    updated_at = models.DateTimeField("Zaktualizowano", auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Zgłoszenie"
        verbose_name_plural = "Zgłoszenia"

    def __str__(self):
        return f"{self.title} ({self.get_status_display()})"


class Comment(models.Model):
    ticket = models.ForeignKey(
        Ticket,
        verbose_name="Zgłoszenie",
        related_name="comments",
        on_delete=models.CASCADE,
    )
    author = models.ForeignKey(
        User,
        verbose_name="Autor",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    text = models.TextField("Treść")
    created_at = models.DateTimeField("Utworzono", auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        verbose_name = "Komentarz"
        verbose_name_plural = "Komentarze"

    def __str__(self):
        return f"Komentarz do {self.ticket_id}"