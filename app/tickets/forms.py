"""Formularze publiczne i formularze panelu operatora."""

from django import forms
from django.contrib.auth.models import User

from .models import Comment, Ticket


class OperatorChoiceField(forms.ModelChoiceField):
    """Pokazuje czytelna nazwe operatora zamiast identyfikatora Entra."""

    def label_from_instance(self, user):
        return user.get_full_name() or user.email or user.username


class TicketCreateForm(forms.ModelForm):
    class Meta:
        model = Ticket
        fields = ["requester_email", "title", "description", "priority", "attachment"]
        widgets = {"description": forms.Textarea(attrs={"rows": 6})}


class TicketOperatorForm(forms.ModelForm):
    """Pola zmieniane przez operatora podczas obsługi zgłoszenia."""

    assigned_to = OperatorChoiceField(
        queryset=User.objects.none(),
        required=False,
        label="Operator",
    )

    class Meta:
        model = Ticket
        fields = ["status", "priority", "assigned_to"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["assigned_to"].queryset = User.objects.filter(
            is_active=True,
            is_staff=True,
        ).order_by("username")


class CommentForm(forms.ModelForm):
    """Wewnętrzna notatka widoczna tylko dla operatorów."""

    class Meta:
        model = Comment
        fields = ["text"]
        widgets = {"text": forms.Textarea(attrs={"rows": 4})}
