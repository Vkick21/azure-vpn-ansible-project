from django.contrib.auth import views as auth_views
from django.urls import path

from .views import (
    OperatorCommentCreateView,
    OperatorTicketDetailView,
    OperatorTicketListView,
    OperatorTicketUpdateView,
    TicketCreateView,
    TicketSuccessView,
    health,
)

urlpatterns = [
    path("", TicketCreateView.as_view(), name="ticket-create"),
    path("success/<uuid:pk>/", TicketSuccessView.as_view(), name="ticket-success"),
    path("health/", health, name="health"),
    path(
        "operator/login/",
        auth_views.LoginView.as_view(template_name="registration/login.html"),
        name="operator-login",
    ),
    path(
        "operator/logout/",
        auth_views.LogoutView.as_view(next_page="operator-login"),
        name="operator-logout",
    ),
    path("operator/", OperatorTicketListView.as_view(), name="operator-ticket-list"),
    path(
        "operator/tickets/<uuid:pk>/",
        OperatorTicketDetailView.as_view(),
        name="operator-ticket-detail",
    ),
    path(
        "operator/tickets/<uuid:pk>/update/",
        OperatorTicketUpdateView.as_view(),
        name="operator-ticket-update",
    ),
    path(
        "operator/tickets/<uuid:pk>/comments/",
        OperatorCommentCreateView.as_view(),
        name="operator-comment-create",
    ),
]
