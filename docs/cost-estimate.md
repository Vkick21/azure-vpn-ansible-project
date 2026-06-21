# Kosztorys Azure — VKICKHAMSTER Helpdesk

Region referencyjny: West Europe

## Szacunek miesięczny

Na podstawie kalkulatora Microsoft Azure przyjęto koszt około **353,34 USD miesięcznie** i **4 240,05 USD rocznie** dla środowiska działającego przez 730 godzin miesięcznie. Kwota jest orientacyjna i zależy od cennika subskrypcji, transferu, liczby logów oraz czasu pracy zasobów.

Kalkulacja obejmuje trzy maszyny `Standard_B1s` z systemem Linux i trzema dyskami S4, Azure Bastion Basic, VPN Gateway VpnGw1AZ, konto Storage, Azure Monitor oraz dwa moduły Azure Load Balancer.

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

## Demonstracja trybu oszczednego

Polecenie ponizej generuje tylko plan usuniecia Bastiona. VPN pozostaje wymagany i aktywny. Polecenie nie wykonuje zadnej zmiany w Azure:

```powershell
.\env.ps1 -Action cost-plan
```

Plan docelowej architektury prywatnej usuwa publiczny LB, publiczny adres
aplikacji, Traffic Manager i Bastion, ale zachowuje VPN oraz dane:

```powershell
.\env.ps1 -Action private-plan
```

Na prezentacji nalezy pokazac podsumowanie planu, a nastepnie przerwac na etapie przed `terraform apply`. Zatrzymanie trzech VM przez `.\env.ps1 -Action stop` jest osobna operacja i nie usuwa dyskow ani danych PostgreSQL.
