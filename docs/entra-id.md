# Microsoft Entra ID dla VKICKHAMSTER Helpdesk

Panel operatora używa logowania Microsoft przez OpenID Connect.

## Konfiguracja

- Tenant ID: <ENTRA_TENANT_ID>
- Client ID: <ENTRA_CLIENT_ID>
- Grupa operatorów: VKICKHAMSTER Helpdesk Operators
- Group ID: <ENTRA_OPERATOR_GROUP_ID>
- Callback: https://<HELPDESK_FQDN>/oidc/callback/
- Sekret w Key Vault: entra-client-secret

Wartość sekretu nie znajduje się w repozytorium. Serwery pobierają ją z Key Vault przez Managed Identity.

## Dostęp operatora

Użytkownik musi należeć do grupy VKICKHAMSTER Helpdesk Operators.
Członkami zarządza skrypt entra-operators.ps1.

    .entra-operators.ps1 -Action List
    .entra-operators.ps1 -Action Add -UserPrincipalName user@example.com
    .entra-operators.ps1 -Action Remove -UserPrincipalName user@example.com

Lokalne konto helpdesk-admin pozostaje kontem awaryjnym.

## Rotacja sekretu

Bieżący sekret wygasa 20 czerwca 2027 roku. Nową wartość należy utworzyć w rejestracji aplikacji i zapisać jako nową wersję sekretu entra-client-secret w Key Vault. Po rotacji aplikację trzeba zrestartować na obu backendach.

## Wymagany VPN dla panelu

Publiczny formularz pozostaje dostępny z Internetu. Panel operatora i callback Entra są dostępne wyłącznie przez VPN.

Na komputerze operatora uruchom PowerShell jako administrator:

    .operator-vpn-access.ps1 -Action Add

Kontrola połączenia:

    .operator-vpn-access.ps1 -Action Status

Usunięcie prywatnego mapowania:

    .operator-vpn-access.ps1 -Action Remove
