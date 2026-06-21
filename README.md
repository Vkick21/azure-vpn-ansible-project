# VKICKHAMSTER Helpdesk na Azure

[![CI](https://github.com/Vkick21/azure-vpn-ansible-project/actions/workflows/ci.yml/badge.svg)](https://github.com/Vkick21/azure-vpn-ansible-project/actions/workflows/ci.yml)

## Autor

- Jan Michalak
- e-mail akademicki: `110997@student.san.edu.pl`
- Społeczna Akademia Nauk

Szczegóły autorstwa znajdują się również w pliku [`AUTHORS.md`](AUTHORS.md).

Projekt przedstawia kompletny system Helpdesk uruchomiony w Microsoft Azure. Infrastruktura jest zarządzana przez Terraform, konfiguracja serwerów przez Ansible, a aplikacja została napisana w Django i korzysta z PostgreSQL.

## Najważniejsze funkcje

- formularz i panel Helpdesk dostępne wyłącznie po VPN;
- logowanie operatorów przez Microsoft Entra ID;
- dwa serwery aplikacyjne za jednym prywatnym Load Balancerem;
- prywatny serwer PostgreSQL bez publicznego adresu IP;
- prywatny runner GitHub Actions `ansible-mgmt` w Azure;
- Terraform i Ansible uruchamiane z GitHub Actions bez WSL;
- załączniki i kopie zapasowe w Azure Storage;
- sekrety przechowywane w Azure Key Vault;
- automatyczny certyfikat Let's Encrypt;
- monitoring przez Azure Monitor i Log Analytics;
- reguły NSG ograniczające ruch między segmentami;
- ochrona formularza przez Google reCAPTCHA v2.

## Dostęp

Po połączeniu VPN formularz jest dostępny pod adresem:

```text
https://<HELPDESK_FQDN>/
```

Formularz i panel operatora wymagają aktywnego VPN oraz prywatnego mapowania domen:

```powershell
.\operator-vpn-access.ps1 -Action Add
```

Usunięcie mapowania:

```powershell
.\operator-vpn-access.ps1 -Action Remove
```

Skrypt mapuje obie nazwy na prywatny Load Balancer `10.10.1.10`.
Po odłączeniu VPN usługa nie jest dostępna.

## Struktura repozytorium

- `*.tf` — infrastruktura Azure;
- `bootstrap/` — osobny stan i konfiguracja VM runnera GitHub Actions;
- `.github/workflows/` — kontrolowane plany, wdrożenia i playbooki;
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

## Konfiguracja lokalna

Rzeczywiste identyfikatory środowiska nie są przechowywane w Git. Przed użyciem skryptów skopiuj plik przykładowy i wpisz własne wartości:

```powershell
Copy-Item .\config.example.ps1 .\config.local.ps1
. .\config.local.ps1
```

Plik `config.local.ps1` jest ignorowany przez Git.

## Google reCAPTCHA v2

Publiczny klucz witryny ustaw w `config.local.ps1` jako `RECAPTCHA_SITE_KEY`.
Prywatny klucz zapisz w istniejącym Azure Key Vault:

```powershell
az keyvault secret set `
  --vault-name $env:KEY_VAULT_NAME `
  --name recaptcha-secret-key `
  --value "<PRYWATNY_KLUCZ_RECAPTCHA>"
```

Prywatnego klucza nie należy zapisywać w repozytorium.

## Podstawowe polecenia

Interaktywny przewodnik do prezentacji projektu:

```powershell
.\presentation-demo.ps1 -OperatorUpn "user@example.com"
```

Opcjonalne automatyczne otwieranie formularza i panelu:

```powershell
.\presentation-demo.ps1 -OperatorUpn "user@example.com" -OpenPages
```

Dodanie operatora przez Ansible uruchamiane z PowerShell:

```powershell
.\add-operator-ansible.ps1 -UserPrincipalName "user@example.com"
```

Skrypt dodaje konto do grupy operatorow Entra ID. Dostep VPN jest
prezentowany z przygotowanego hosta, na ktorym profil i certyfikat klienta
zostaly zainstalowane przed prezentacja.

Walidacja i plan Terraform:

```powershell
terraform validate
.\env.ps1 -Action plan
```

Workflow `terraform-apply.yml` wymaga jawnego potwierdzenia. Każde wdrożenie musi zostać poprzedzone przeglądem planu.

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
- [Plan optymalizacji kosztow](docs/cost-optimization-plan.md)
- [Microsoft Entra ID](docs/entra-id.md)
- [GitHub Actions na VM zarzadzajacej](docs/github-runner.md)
- [Migracja tylko przez VPN](docs/private-only-migration.md)
- [Dowody wdrożenia i testów](docs/evidence/test-summary.md)

## Demonstracja kontroli kosztow

Zwykly plan potwierdza zgodnosc dzialajacego srodowiska:

```powershell
.\env.ps1 -Action plan
```

Plan oszczedny usuwa tylko Bastiona, zachowuje wymagany VPN i nie wykonuje `terraform apply`:

```powershell
.\env.ps1 -Action cost-plan
```

Plan dostepu tylko przez VPN i jednego prywatnego Load Balancera:

```powershell
.\env.ps1 -Action private-plan
```

Automatyzacja GitHub Actions korzysta z osobnej VM `ansible-mgmt`. Jej kod
znajduje sie w `bootstrap/`, a glowny Terraform nie moze jej restartowac ani
usunac.

Maszyny aplikacji i bazy mozna zatrzymac bez niszczenia infrastruktury:

```powershell
.\env.ps1 -Action stop
.\env.ps1 -Action start
```
