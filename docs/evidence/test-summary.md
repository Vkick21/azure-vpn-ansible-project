# Wyniki testów odbiorczych

Data wykonania: 20 czerwca 2026 r.

| Obszar | Test | Wynik |
|---|---|---|
| Formularz publiczny | HTTPS przez publiczny Load Balancer | `200 OK` |
| Formularz publiczny | Widget reCAPTCHA v2 i klucz witryny | widoczne |
| Formularz publiczny | Wysłanie bez tokenu reCAPTCHA | odrzucone, brak nowego zgłoszenia |
| Panel operatora | Dostęp przez publiczny Load Balancer | `403 Forbidden` |
| Panel operatora | Dostęp przez prywatny Load Balancer i VPN | `302` do logowania |
| Microsoft Entra ID | Wejście przez prywatny Load Balancer i VPN | `302` do Microsoft Login |
| SSH | Ansible ping do helpdesk01 | poprawny |
| SSH | Ansible ping do helpdesk02 | poprawny |
| SSH | Ansible ping do helpdesk-db01 | poprawny |
| PostgreSQL | TCP/5432 z helpdesk01 | dostępny |
| PostgreSQL | TCP/5432 z helpdesk02 | dostępny |
| Usługi | Django/Gunicorn i Nginx | aktywne na obu backendach |
| Usługi | PostgreSQL i timer backupu | aktywne |
| DNS | Rozwiązywanie nazw z wszystkich VM | poprawne |
| HTTPS wychodzący | Połączenie z Azure Management | poprawne z wszystkich VM |
| Terraform | Plan po wdrożeniu | `No changes` |
| Django | Testy jednostkowe | 14/14 |

Testy sieciowe po wdrożeniu reguł NSG były tylko odczytowe i nie zmieniały danych w PostgreSQL.

## Interpretacja

Publiczny formularz pozostaje dostępny dla użytkowników Internetu, ale zapis zgłoszenia wymaga poprawnego tokenu Google reCAPTCHA v2. Panel operatora oraz logowanie Entra ID są blokowane od strony publicznej i działają przez prywatny Load Balancer po zestawieniu VPN. Oba backendy zachowały dostęp do bazy, DNS i wymaganych usług HTTPS.
