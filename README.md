# VKICKHAMSTER Helpdesk na Azure

Projekt przedstawia kompletny system Helpdesk uruchomiony w Microsoft Azure. Infrastruktura jest zarządzana przez Terraform, konfiguracja serwerów przez Ansible, a aplikacja została napisana w Django i korzysta z PostgreSQL.

## Najważniejsze funkcje

- publiczny formularz zgłoszenia dostępny przez HTTPS;
- panel operatora dostępny wyłącznie po VPN;
- logowanie operatorów przez Microsoft Entra ID;
- dwa serwery aplikacyjne za publicznym i prywatnym Load Balancerem;
- prywatny serwer PostgreSQL bez publicznego adresu IP;
- załączniki i kopie zapasowe w Azure Storage;
- sekrety przechowywane w Azure Key Vault;
- automatyczny certyfikat Let's Encrypt;
- monitoring przez Azure Monitor i Log Analytics;
- reguły NSG ograniczające ruch między segmentami.

## Dostęp

Publiczny formularz:

```text
https://helpdesk-demo.example.com/
```

Panel operatora wymaga aktywnego VPN oraz prywatnego mapowania domeny:

```powershell
.\operator-vpn-access.ps1 -Action Add
```

Usunięcie mapowania:

```powershell
.\operator-vpn-access.ps1 -Action Remove
```

## Struktura repozytorium

- `*.tf` — infrastruktura Azure;
- `ansible/` — konfiguracja Linux, Nginx, Django, PostgreSQL, HTTPS i backup;
- `app/` — aplikacja Django Helpdesk;
- `docs/project-report.md` — pełne sprawozdanie techniczne;
- `docs/network-security.md` — routing i reguły NSG;
- `docs/cost-estimate.md` — kosztorys Azure;
- `docs/entra-id.md` — logowanie Entra ID;
- `azure-cost-report.ps1` — eksport kosztów i zasobów do CSV;
- `env.ps1` — planowanie oraz sterowanie środowiskiem;
- `entra-operators.ps1` — zarządzanie grupą operatorów;
- `operator-vpn-access.ps1` — prywatne mapowanie domeny panelu.

## Podstawowe polecenia

Walidacja i plan Terraform:

```powershell
terraform validate
.\env.ps1 -Action plan
```

Projekt nie zakłada automatycznego wykonywania `terraform apply`. Każde wdrożenie powinno zostać poprzedzone przeglądem planu.

Test składni Ansible:

```powershell
wsl bash -lc "cd /mnt/c/Projects/terraform/ansible && ansible-playbook -i inventory.ini verify-helpdesk.yml --syntax-check"
```

Aktualizacja kosztorysu:

```powershell
.\azure-cost-report.ps1
```

## Dokumentacja

- [Sprawozdanie projektu](docs/project-report.md)
- [Routing i NSG](docs/network-security.md)
- [Kosztorys](docs/cost-estimate.md)
- [Microsoft Entra ID](docs/entra-id.md)
- [Dowody wdrożenia i testów](docs/evidence/test-summary.md)