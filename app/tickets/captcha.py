"""Weryfikacja publicznego formularza przez Google reCAPTCHA."""

import json
from urllib import parse, request

from django.conf import settings


def verify_recaptcha(token):
    """Zwraca True tylko dla tokenu zaakceptowanego przez Google."""
    if not token:
        return False

    payload = parse.urlencode(
        {"secret": settings.RECAPTCHA_SECRET_KEY, "response": token}
    ).encode("utf-8")

    try:
        verification_request = request.Request(
            settings.RECAPTCHA_VERIFY_URL,
            data=payload,
            method="POST",
        )
        with request.urlopen(verification_request, timeout=5) as response:
            result = json.loads(response.read().decode("utf-8"))
    except (OSError, ValueError, json.JSONDecodeError):
        return False

    return result.get("success") is True
