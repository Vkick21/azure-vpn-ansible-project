# GitHub Actions na VM ansible-mgmt

VM `ansible-mgmt` dziala jako self-hosted runner wewnatrz VNet. Terraform i
Ansible nie wymagaja WSL ani publicznego SSH do serwerow aplikacji.

## Rozdzielenie stanow Terraform

- `bootstrap/` uzywa klucza `bootstrap.tfstate` i zarzadza tylko runnerem;
- katalog glowny uzywa `terraform.tfstate` i zarzadza Helpdeskiem;
- `prevent_destroy` chroni runner przed przypadkowym usunieciem.

## Kolejnosc uruchomienia

1. Sprawdz `terraform -chdir=bootstrap plan`.
2. Po osobnej akceptacji utworz VM przez `terraform -chdir=bootstrap apply`.
3. Polacz VPN i wejdz przez SSH na `10.10.2.10`.
4. Pobierz aktualna wersje, sume SHA256 i token runnera z ustawien GitHub.
5. Uruchom `bootstrap/register-runner.sh` na VM.
6. Dodaj publiczny klucz runnera playbookiem `authorize-management-runner.yml`.
7. Utworz srodowisko GitHub `production` z wymaganym zatwierdzeniem.

## Zmienne repozytorium GitHub

W `Settings -> Secrets and variables -> Actions -> Variables` dodaj:

- `TF_VAR_HELPDESK_DNS_LABEL`;
- `TF_VAR_OPERATOR_DNS_LABEL`;
- `TF_VAR_PRIVATE_ONLY`;
- `TF_VAR_KEY_VAULT_ADMIN_OBJECT_IDS` jako tablice JSON;
- `TF_SSH_PUBLIC_KEY` z dotychczasowym kluczem publicznym VM;
- `HELPDESK_FQDN` i `HELPDESK_OPERATOR_FQDN`;
- `HELPDESK_PUBLIC_IP`, `HELPDESK_PRIVATE_IP`, `HELPDESK_DATABASE_IP`;
- `AZURE_STORAGE_ACCOUNT`, `KEY_VAULT_NAME`;
- `ENTRA_TENANT_ID`, `ENTRA_CLIENT_ID`, `ENTRA_OPERATOR_GROUP_ID`;
- `RECAPTCHA_SITE_KEY`.

Do workflow start/stop runnera dodaj rowniez wartosci z `terraform output`
stosu bootstrap:

- `AZURE_RUNNER_CONTROL_CLIENT_ID`;
- `AZURE_TENANT_ID`;
- `AZURE_SUBSCRIPTION_ID`.

Nie zapisuj w GitHub hasel bazy, prywatnych kluczy SSH ani sekretu reCAPTCHA.
Serwery pobieraja sekrety z Key Vault przez Managed Identity.

## Workflow

- `terraform-plan.yml` tylko pokazuje plan;
- `terraform-apply.yml` wymaga wpisania `APPLY` i akceptacji `production`;
- `ansible-deploy.yml` uruchamia tylko wybrany bezpieczny playbook.
- `management-vm-control.yml` uruchamia lub deallokuje runner przez OIDC.

Workflow self-hosted sa uruchamiane tylko recznie. Nie nalezy uruchamiac na
runnerze kodu z niezaufanych Pull Requestow.
