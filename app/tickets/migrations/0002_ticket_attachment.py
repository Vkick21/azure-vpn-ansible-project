# Dodajemy opcjonalny załącznik przechowywany w Azure Storage.

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("tickets", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="ticket",
            name="attachment",
            field=models.FileField(blank=True, upload_to="tickets/%Y/%m/", verbose_name="Załącznik"),
        ),
    ]