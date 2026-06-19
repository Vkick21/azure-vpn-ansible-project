"""Panel operatora do obsługi zgłoszeń."""

from django.contrib import admin

from .models import Comment, Ticket


class CommentInline(admin.TabularInline):
    model = Comment
    extra = 1


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "requester_email",
        "priority",
        "status",
        "assigned_to",
        "created_at",
    )
    list_filter = ("priority", "status", "assigned_to")
    search_fields = ("title", "description", "requester_email")
    readonly_fields = ("id", "created_at", "updated_at")
    inlines = [CommentInline]


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ("ticket", "author", "created_at")
    search_fields = ("ticket__title", "text")