"""Logowanie operatorów przez Microsoft Entra ID."""

import os

from django.contrib.auth.models import User
from mozilla_django_oidc.auth import OIDCAuthenticationBackend


class EntraOperatorBackend(OIDCAuthenticationBackend):
    """Dopuszcza tylko członków wskazanej grupy operatorów."""

    def get_userinfo(self, access_token, id_token, payload):
        """Łączy profil użytkownika ze zweryfikowanymi claimami tokenu ID."""
        userinfo = super().get_userinfo(access_token, id_token, payload)
        for claim_name in ("groups", "oid", "tid"):
            if claim_name in payload:
                userinfo[claim_name] = payload[claim_name]
        return userinfo
    def verify_claims(self, claims):
        allowed_group = os.environ.get("ENTRA_OPERATOR_GROUP_ID", "")
        groups = claims.get("groups", [])
        return bool(claims.get("sub") and allowed_group and allowed_group in groups)

    @staticmethod
    def _username(claims):
        object_id = claims.get("oid") or claims["sub"]
        return f"entra-{object_id}"

    def filter_users_by_claims(self, claims):
        return User.objects.filter(username=self._username(claims))

    def create_user(self, claims):
        user = User(
            username=self._username(claims),
            email=claims.get("preferred_username") or claims.get("email", ""),
            first_name=claims.get("given_name", ""),
            last_name=claims.get("family_name", ""),
            is_staff=True,
            is_active=True,
        )
        user.set_unusable_password()
        user.save()
        return user

    def update_user(self, user, claims):
        user.email = claims.get("preferred_username") or claims.get("email", "")
        user.first_name = claims.get("given_name", "")
        user.last_name = claims.get("family_name", "")
        user.is_staff = True
        user.is_active = True
        user.save(
            update_fields=[
                "email",
                "first_name",
                "last_name",
                "is_staff",
                "is_active",
            ]
        )
        return user
