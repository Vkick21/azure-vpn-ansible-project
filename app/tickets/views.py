"""Widoki publicznego formularza i kontroli zdrowia aplikacji."""

from django.db import connection
from django.http import JsonResponse
from django.urls import reverse
from django.views.generic import CreateView, DetailView

from .forms import TicketCreateForm
from .models import Ticket


class TicketCreateView(CreateView):
    model = Ticket
    form_class = TicketCreateForm
    template_name = "tickets/ticket_create.html"

    def get_success_url(self):
        return reverse("ticket-success", kwargs={"pk": self.object.pk})


class TicketSuccessView(DetailView):
    model = Ticket
    template_name = "tickets/ticket_success.html"


def health(request):
    """Kontrola Load Balancera sprawdza aplikację oraz bazę."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except Exception:
        return JsonResponse({"status": "error", "database": "unavailable"}, status=503)

    return JsonResponse({"status": "ok", "database": "available"})