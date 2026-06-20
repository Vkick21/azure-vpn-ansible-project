"""Widoki formularza publicznego, zdrowia i panelu operatora."""

from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.contrib.auth.models import User
from django.core.exceptions import PermissionDenied
from django.db import connection
from django.db.models import Q
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.urls import reverse
from django.views.generic import CreateView, DetailView, FormView, ListView, UpdateView

from .forms import CommentForm, TicketCreateForm, TicketOperatorForm
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


class OperatorRequiredMixin(LoginRequiredMixin, UserPassesTestMixin):
    """Dopuszcza tylko zalogowane, aktywne konta pracowników."""

    def test_func(self):
        user = self.request.user
        return user.is_active and user.is_staff

    def handle_no_permission(self):
        if self.request.user.is_authenticated:
            raise PermissionDenied("Panel jest dostępny tylko dla operatorów.")
        return super().handle_no_permission()


class OperatorTicketListView(OperatorRequiredMixin, ListView):
    model = Ticket
    template_name = "tickets/operator_list.html"
    context_object_name = "tickets"
    paginate_by = 20

    def get_queryset(self):
        queryset = super().get_queryset().select_related("assigned_to")
        query = self.request.GET.get("q", "").strip()
        status = self.request.GET.get("status", "").strip()
        priority = self.request.GET.get("priority", "").strip()
        assigned_to = self.request.GET.get("assigned_to", "").strip()

        if query:
            queryset = queryset.filter(
                Q(title__icontains=query)
                | Q(description__icontains=query)
                | Q(requester_email__icontains=query)
                | Q(id__icontains=query)
            )
        if status in Ticket.Status.values:
            queryset = queryset.filter(status=status)
        if priority in Ticket.Priority.values:
            queryset = queryset.filter(priority=priority)
        if assigned_to == "unassigned":
            queryset = queryset.filter(assigned_to__isnull=True)
        elif assigned_to.isdigit():
            queryset = queryset.filter(assigned_to_id=int(assigned_to))
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["status_choices"] = Ticket.Status.choices
        context["priority_choices"] = Ticket.Priority.choices
        context["operators"] = User.objects.filter(
            is_active=True,
            is_staff=True,
        ).order_by("username")
        context["filters"] = self.request.GET
        return context


class OperatorTicketDetailView(OperatorRequiredMixin, DetailView):
    model = Ticket
    template_name = "tickets/operator_detail.html"
    context_object_name = "ticket"

    def get_queryset(self):
        return (
            super()
            .get_queryset()
            .select_related("assigned_to")
            .prefetch_related("comments__author")
        )

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["ticket_form"] = TicketOperatorForm(instance=self.object)
        context["comment_form"] = CommentForm()
        return context


class OperatorTicketUpdateView(OperatorRequiredMixin, UpdateView):
    model = Ticket
    form_class = TicketOperatorForm
    http_method_names = ["post"]

    def form_valid(self, form):
        messages.success(self.request, "Zgłoszenie zostało zaktualizowane.")
        return super().form_valid(form)

    def get_success_url(self):
        return reverse("operator-ticket-detail", kwargs={"pk": self.object.pk})


class OperatorCommentCreateView(OperatorRequiredMixin, FormView):
    form_class = CommentForm
    http_method_names = ["post"]

    def dispatch(self, request, *args, **kwargs):
        self.ticket = get_object_or_404(Ticket, pk=kwargs["pk"])
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        comment = form.save(commit=False)
        comment.ticket = self.ticket
        comment.author = self.request.user
        comment.save()
        messages.success(self.request, "Dodano komentarz wewnętrzny.")
        return super().form_valid(form)

    def get_success_url(self):
        return reverse("operator-ticket-detail", kwargs={"pk": self.ticket.pk})


def health(request):
    """Kontrola Load Balancera sprawdza aplikację oraz bazę."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except Exception:
        return JsonResponse({"status": "error", "database": "unavailable"}, status=503)
    return JsonResponse({"status": "ok", "database": "available"})
