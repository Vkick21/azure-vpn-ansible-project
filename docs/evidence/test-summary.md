# Wyniki testów odbiorczych

Data ostatniej pełnej weryfikacji: 21 czerwca 2026 r.

| Obszar | Test | Wynik |
|---|---|---|
| Helpdesk | Dostęp bez VPN | niedostępny zgodnie z projektem |
| Helpdesk | HTTPS przez prywatny Load Balancer i VPN | poprawny |
| Formularz | Widget i walidacja Google reCAPTCHA v2 | poprawne |
| Panel operatora | Przekierowanie do logowania Entra przez VPN | poprawne |
| Load Balancer | Liczba modułów | jeden prywatny LB |
| SSH | Ansible do trzech VM roboczych z runnera | poprawny |
| PostgreSQL | TCP/5432 z obu backendów | dostępny |
| Usługi | Django, Gunicorn, Nginx i PostgreSQL | aktywne |
| Wyjście backendów | Key Vault, Internet i Storage | dostępne |
| Publiczne wejście | Reguły NSG z Internetu | brak reguł zezwalających |
| GitHub Actions | `verify-helpdesk.yml` | zakończony powodzeniem |
| Terraform | Końcowy plan | `No changes` |
| Django | Testy jednostkowe | 14/14 |

Prywatny health check zwrócił `database: available`. Testy nie modyfikowały istniejących danych PostgreSQL.
