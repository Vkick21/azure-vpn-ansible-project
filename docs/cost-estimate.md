# Kosztorys Azure — VKICKHAMSTER Helpdesk

Region referencyjny: West Europe

## Szacunek miesięczny

Na podstawie obserwowanego profilu usług przyjęto przedział **235–300 EUR miesięcznie** dla środowiska działającego przez całą dobę. Kwota jest orientacyjna i zależy od cennika subskrypcji, transferu, liczby logów oraz czasu pracy zasobów.

Największe składniki kosztu:

| Usługa | Znaczenie w kosztorysie |
|---|---|
| Azure Bastion | wysoki koszt stały |
| VPN Gateway | wysoki koszt stały |
| Virtual Machines B1s | niski koszt obliczeń |
| Storage | koszt zależny od danych i operacji |
| Log Analytics | koszt zależny od ilości logów |
| Key Vault | niski koszt operacji |
| Load Balancer i transfer | zależne od użycia |

## Najważniejsze wnioski

1. Bastion i VPN Gateway generują większość kosztu stałego.
2. Wyłączenie VM ogranicza koszt obliczeń, ale nie zatrzymuje naliczania za Bastion i VPN Gateway.
3. Trzy VM `Standard_B1s` są oszczędnym wyborem dla środowiska demonstracyjnego.
4. Usunięcie Bastiona poza prezentacjami daje największą oszczędność, ale pozostawia administrację zależną od VPN.
5. VPN Gateway jest wymagany dla prywatnego panelu operatora.

## Raport rzeczywisty

Rzeczywiste dane rozliczeniowe nie są publikowane. Można je wygenerować lokalnie:

```powershell
cd C:\Projects\terraform
.\azure-cost-report.ps1
```

Skrypt zapisuje pliki CSV w `docs/costs/`. Ten katalog jest ignorowany przez Git. Skrypt używa bieżącej sesji Azure CLI, a token pozostaje wyłącznie w pamięci procesu.