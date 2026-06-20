from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse

from .models import Comment, Ticket


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
        self.assertTrue(ticket.attachment.name.endswith(".txt"))
        self.assertTrue(ticket.attachment.storage.exists(ticket.attachment.name))


class OperatorPanelTests(TestCase):
    def setUp(self):
        self.operator = User.objects.create_user(
            username="operator",
            password="safe-test-password",
            is_staff=True,
        )
        self.regular_user = User.objects.create_user(
            username="regular",
            password="safe-test-password",
        )
        self.ticket = Ticket.objects.create(
            requester_email="client@example.com",
            title="Brak dostępu do VPN",
            description="Klient nie może połączyć się z VPN.",
            priority=Ticket.Priority.HIGH,
        )

    def test_anonymous_user_is_redirected_to_login(self):
        response = self.client.get(reverse("operator-ticket-list"))
        self.assertRedirects(
            response,
            f"{reverse('operator-login')}?next={reverse('operator-ticket-list')}",
        )

    def test_user_without_staff_role_is_forbidden(self):
        self.client.force_login(self.regular_user)
        response = self.client.get(reverse("operator-ticket-list"))
        self.assertEqual(response.status_code, 403)

    def test_operator_can_filter_tickets(self):
        Ticket.objects.create(
            requester_email="other@example.com",
            title="Problem z drukarką",
            description="Brak wydruku.",
            priority=Ticket.Priority.LOW,
        )
        self.client.force_login(self.operator)
        response = self.client.get(
            reverse("operator-ticket-list"),
            {"q": "VPN", "priority": Ticket.Priority.HIGH},
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Brak dostępu do VPN")
        self.assertNotContains(response, "Problem z drukarką")

    def test_operator_can_update_ticket(self):
        self.client.force_login(self.operator)
        response = self.client.post(
            reverse("operator-ticket-update", kwargs={"pk": self.ticket.pk}),
            {
                "status": Ticket.Status.IN_PROGRESS,
                "priority": Ticket.Priority.URGENT,
                "assigned_to": self.operator.pk,
            },
        )
        self.assertRedirects(
            response,
            reverse("operator-ticket-detail", kwargs={"pk": self.ticket.pk}),
        )
        self.ticket.refresh_from_db()
        self.assertEqual(self.ticket.status, Ticket.Status.IN_PROGRESS)
        self.assertEqual(self.ticket.priority, Ticket.Priority.URGENT)
        self.assertEqual(self.ticket.assigned_to, self.operator)

    def test_operator_comment_records_author(self):
        self.client.force_login(self.operator)
        response = self.client.post(
            reverse("operator-comment-create", kwargs={"pk": self.ticket.pk}),
            {"text": "Sprawdzono konfigurację klienta VPN."},
        )
        self.assertRedirects(
            response,
            reverse("operator-ticket-detail", kwargs={"pk": self.ticket.pk}),
        )
        comment = Comment.objects.get(ticket=self.ticket)
        self.assertEqual(comment.author, self.operator)
        self.assertEqual(comment.text, "Sprawdzono konfigurację klienta VPN.")
