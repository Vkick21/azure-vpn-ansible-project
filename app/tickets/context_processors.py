"""Wspolne adresy formularza i panelu operatora dla szablonow."""

from django.conf import settings


def service_urls(request):
    """Udostepnia bezpieczne adresy przejscia miedzy dwiema domenami."""
    return {
        "public_base_url": settings.PUBLIC_BASE_URL,
        "operator_base_url": settings.OPERATOR_BASE_URL,
    }
