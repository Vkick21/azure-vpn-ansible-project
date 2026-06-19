"""Formularz dostępny dla osoby zgłaszającej problem."""

from django import forms

from .models import Ticket


class TicketCreateForm(forms.ModelForm):
    class Meta:
        model = Ticket
        fields = ["requester_email", "title", "description", "priority", "attachment"]
        widgets = {
            "description": forms.Textarea(attrs={"rows": 6}),
        }