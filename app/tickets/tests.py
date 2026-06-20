from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch

from .oidc import EntraOperatorBackend

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

class EntraOperatorBackendTests(TestCase):
    def setUp(self):
        self.backend = EntraOperatorBackend()
        self.claims = {
            "sub": "entra-subject",
            "oid": "11111111-2222-3333-4444-555555555555",
            "preferred_username": "operator@example.com",
            "given_name": "Jan",
            "family_name": "Operator",
            "groups": ["allowed-group"],
        }

    @patch.dict("os.environ", {"ENTRA_OPERATOR_GROUP_ID": "allowed-group"})
    def test_member_of_operator_group_is_accepted(self):
        self.assertTrue(self.backend.verify_claims(self.claims))

    @patch.dict("os.environ", {"ENTRA_OPERATOR_GROUP_ID": "different-group"})
    def test_user_outside_operator_group_is_rejected(self):
        self.assertFalse(self.backend.verify_claims(self.claims))

    def test_created_entra_user_is_staff_without_local_password(self):
        user = self.backend.create_user(self.claims)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_active)
        self.assertFalse(user.has_usable_password())
        self.assertEqual(user.email, "operator@example.com")
        self.assertEqual(user.username, "entra-11111111-2222-3333-4444-555555555555")
    @patch(
        "tickets.oidc.OIDCAuthenticationBackend.get_userinfo",
        return_value={"sub": "entra-subject", "email": "operator@example.com"},
    )
    def test_signed_id_token_groups_are_merged(self, parent_get_userinfo):
        result = self.backend.get_userinfo(
            "access-token",
            "id-token",
            {
                "oid": "11111111-2222-3333-4444-555555555555",
                "groups": ["allowed-group"],
            },
        )
        self.assertEqual(result["groups"], ["allowed-group"])
        self.assertEqual(result["oid"], "11111111-2222-3333-4444-555555555555")
        parent_get_userinfo.assert_called_once()
