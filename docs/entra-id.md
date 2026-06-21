# Microsoft Entra ID dla VKICKHAMSTER Helpdesk

Panel operatora używa logowania Microsoft przez OpenID Connect.

## Konfiguracja

- Tenant ID: `<ENTRA_TENANT_ID>`
- Client ID: `<ENTRA_CLIENT_ID>`
- Grupa operatorów: `VKICKHAMSTER Helpdesk Operators`
- Group ID: `<ENTRA_OPERATOR_GROUP_ID>`
- Callback: `https://<HELPDESK_OPERATOR_FQDN>/oidc/callback/`
- Sekret w Key Vault: `entra-client-secret`

Wartość sekretu nie znajduje się w repozytorium. Serwery pobierają ją z Key Vault przez Managed Identity.

## Dostęp operatora

Operator musi należeć do grupy Entra ID oraz połączyć się z VPN. Członkostwem zarządza skrypt:

```powershell
.\entra-operators.ps1 -Action List
.\entra-operators.ps1 -Action Add -UserPrincipalName user@example.com
.\entra-operators.ps1 -Action Remove -UserPrincipalName user@example.com
```

Lokalne konto administratora pozostaje kontem awaryjnym.

## Dostęp wyłącznie przez VPN

Formularz, panel operatora oraz callback Entra kierują do prywatnego Load Balancera `10.10.1.10`. Bez aktywnego VPN usługa nie jest dostępna.

Na komputerze operatora uruchom PowerShell jako administrator:

```powershell
.\operator-vpn-access.ps1 -Action Add
.\operator-vpn-access.ps1 -Action Status
.\operator-vpn-access.ps1 -Action Remove
```

Skrypt zarządza lokalnym mapowaniem nazwy na prywatny adres. Nie tworzy konta Entra ani certyfikatu VPN.

## Zarządzanie operatorami przez Ansible

Playbook `ansible/manage-operator.yml` idempotentnie zarządza członkostwem w grupie Entra ID:

```bash
ansible-playbook manage-operator.yml -e operator_action=list
ansible-playbook manage-operator.yml -e operator_action=add -e operator_upn=user@example.com
ansible-playbook manage-operator.yml -e operator_action=remove -e operator_upn=user@example.com
```

Profil Azure VPN Client i certyfikat klienta są przygotowywane osobno na komputerze operatora. Rozdziela to dostęp sieciowy od uprawnień w aplikacji.
