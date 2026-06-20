"""Adresy aplikacji i panelu administratora."""

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("oidc/", include("mozilla_django_oidc.urls")),
    path("admin/", admin.site.urls),
    path("", include("tickets.urls")),
]