VKICKHAMSTER Helpdesk - pliki dodatkowe
=======================================

Archiwum zawiera niewrazliwa kopie kodu i dokumentacji projektu.

Najwazniejsze katalogi i pliki:

1. Pliki *.tf
   Definicje infrastruktury Microsoft Azure przygotowane w Terraform.

2. ansible/
   Inventory, playbooki wdrozenia Django, PostgreSQL, HTTPS, backupu,
   testow oraz zarzadzania operatorami Microsoft Entra ID.

3. app/
   Kod aplikacji Django Helpdesk, formularz publiczny z reCAPTCHA v2,
   panel operatora oraz testy jednostkowe.

4. Skrypty *.ps1
   Sterowanie srodowiskiem, dostep operatora przez VPN, raport kosztow
   interaktywny przewodnik presentation-demo.ps1 oraz prosty skrypt
   add-operator-ansible.ps1 dodajacy operatora przez Ansible w WSL.

5. docs/
   Opis projektu, bezpieczenstwa sieci, kosztow, Entra ID i wynikow testow.

6. .github/workflows/
   Kontrole CI dla Terraform, Ansible, PowerShell i Django.

7. config.example.ps1
   Niewrazliwy szablon konfiguracji lokalnej.

Celowo pominiete dane:

- config.local.ps1;
- stan Terraform i zapisane plany;
- prywatne certyfikaty, klucze SSH oraz pliki PFX/PEM;
- sekrety Google reCAPTCHA, Microsoft Entra ID i Django;
- hasla PostgreSQL i kont administracyjnych;
- eksporty kosztow zawierajace dane subskrypcji.

Uruchomienie przewodnika prezentacji:

  cd C:\Projects\terraform
  .\presentation-demo.ps1

Projekt nie wykonuje automatycznie terraform apply. Kazda zmiana
infrastruktury wymaga osobnej akceptacji i sprawdzenia planu.
