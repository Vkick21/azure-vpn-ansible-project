# Plan optymalizacji kosztow

Punkt odniesienia 353,34 USD miesięcznie dotyczył poprzedniej architektury.
W finalnym rozwiązaniu Bastion został usunięty, a największą stałą pozycją
pozostaje wymagany VPN Gateway.

## Zmiany docelowe

| Zmiana | Wplyw |
|---|---|
| Usunięty Azure Bastion | Ograniczenie wysokiego kosztu stałego |
| Jeden prywatny Load Balancer | Brak publicznego modułu LB |
| Usunięty Traffic Manager | Prostsza architektura DNS |
| Dwa outbound-only public IP | Zapewniają aktualizacje i dostęp do usług Azure bez publicznego wejścia |
| Runner Standard_B1s | Niski koszt, szczególnie przy deallokacji poza wdrożeniami |
| VPN Gateway pozostaje | Koszt wymagany przez dostęp wyłącznie po VPN |
| Log Analytics 30 dni | Ograniczenie kosztu przechowywania i pozyskiwania logow |

Po migracji należy ponownie wyeksportować kalkulację Azure. Nie należy podawać
starej sumy jako kosztu finalnego, ponieważ zmieniła się liczba VM, Load
Balancerów i publicznych adresów IP.

## Sterowanie runnerem

Workflow `management-vm-control.yml` dziala na runnerze GitHub-hosted i przez
OIDC wykonuje `start`, `status` albo `deallocate`. Nie przechowuje hasla ani
client secret w GitHub.

## Zasoby, ktorych nie wolno usuwac

- VPN Gateway;
- VM bazy i jej dysk;
- oba serwery aplikacyjne i ich dyski;
- konto Storage z backupami;
- Key Vault;
- zdalny stan Terraform.
