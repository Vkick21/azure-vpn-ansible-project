from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse

from .models import Ticket


class TicketViewsTests(TestCase):
    def test_health_checks_database(self):
        response = self.client.get(reverse("health"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["database"], "available")

    def test_public_form_creates_ticket(self):
        response = self.client.post(
            reverse("ticket-create"),
            {
                "requester_email": "user@example.com",
                "title": "Problem z logowaniem",
                "description": "Nie mogę zalogować się do systemu.",
                "priority": Ticket.Priority.HIGH,
                "attachment": SimpleUploadedFile("error.txt", b"test attachment"),
            },
        )
        ticket = Ticket.objects.get()
        self.assertRedirects(response, reverse("ticket-success", kwargs={"pk": ticket.pk}))
        self.assertEqual(ticket.status, Ticket.Status.NEW)
        self.assertTrue(ticket.attachment.name.endswith("error.txt"))