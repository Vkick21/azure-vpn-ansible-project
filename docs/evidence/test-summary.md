# Wyniki testów odbiorczych

Data ostatniej pełnej weryfikacji: 28 czerwca 2026 r.

| Obszar | Test | Wynik |
|---|---|---|
| Odtwarzanie | Utworzenie backendu stanu i infrastruktury od zera | zakończone powodzeniem |
| Terraform | Końcowy plan z prywatnego runnera | `No changes` |
| GitHub Actions | OIDC, self-hosted runner i chroniony apply | poprawne |
| CI | Terraform, Ansible, PowerShell i Django | poprawne, Django 16/16 |
| Helpdesk | Dostęp bez VPN | niedostępny zgodnie z projektem |
| Helpdesk | HTTPS przez prywatny Load Balancer i VPN | poprawny |
| Formularz | Widget i walidacja Google reCAPTCHA v2 | poprawne |
| Formularz | Zapis zgłoszenia i załącznika | poprawny |
| Panel operatora | Logowanie Microsoft Entra ID i widoczność zgłoszenia | poprawne |
| Load Balancer | Awaria `helpdesk01` | 5/5 odpowiedzi HTTP 200 przez `helpdesk02` |
| Load Balancer | Liczba modułów | jeden prywatny Load Balancer |
| PostgreSQL | Dostęp z backendów aplikacyjnych | poprawny |
| PostgreSQL | Bezpośredni dostęp klienta VPN do TCP/5432 | zablokowany |
| Usługi | Django, Gunicorn, Nginx i PostgreSQL | aktywne |
| HTTPS | Certyfikat obu nazw i synchronizacja przez Storage | poprawne |
| Backup | Jednorazowa kopia oraz timer dzienny | poprawne |
| Publiczne wejście | TCP/80 i TCP/443 na obu publicznych IP VM | zablokowane |

Kontrolowane odtworzenie ujawniło brak backendu stanu, maszyny `ansible-mgmt`
oraz nieaktualną tożsamość OIDC. Elementy zostały odtworzone z kodu, a workflow
Ansible uzupełniono o pełne wdrożenie PostgreSQL i aplikacji po awarii.

Po zakończeniu testu failover Nginx na `helpdesk01` został uruchomiony ponownie.
Oba backendy zwracają lokalny health check HTTP 200, a Load Balancer odpowiada
kodem HTTP 200 z prawidłowo zweryfikowanym certyfikatem TLS.
