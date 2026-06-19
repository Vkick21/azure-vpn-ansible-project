from django.urls import path

from .views import TicketCreateView, TicketSuccessView, health

urlpatterns = [
    path("", TicketCreateView.as_view(), name="ticket-create"),
    path("success/<uuid:pk>/", TicketSuccessView.as_view(), name="ticket-success"),
    path("health/", health, name="health"),
]