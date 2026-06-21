# Kosztorys Azure — VKICKHAMSTER Helpdesk

Region referencyjny: West Europe

## Aktualny zakres kalkulacji

Finalna architektura obejmuje:

- cztery oszczędne maszyny `Standard_B1s`: dwa serwery Django, PostgreSQL i host zarządzający;
- cztery dyski zarządzane;
- Azure VPN Gateway `VpnGw1AZ`;
- jeden prywatny Azure Load Balancer;
- trzy publiczne adresy IP: jeden dla VPN Gateway i dwa wyłącznie do ruchu wychodzącego backendów;
- Azure Storage, Key Vault, Azure Monitor i Log Analytics.

W środowisku nie działają Azure Bastion, Traffic Manager ani publiczny Load Balancer. Formularz i panel operatora są dostępne tylko po VPN.

Poprzednia kwota `353,34 USD` miesięcznie dotyczyła starszej architektury i nie jest aktualnym kosztem finalnego rozwiązania. Dokładną wartość należy ponownie wyeksportować z kalkulatora Azure, ponieważ zależy ona od bieżącego cennika, liczby godzin pracy VM, transferu i ilości logów.

## Najważniejsze wnioski

1. VPN Gateway pozostaje największym wymaganym kosztem stałym.
2. Usunięcie Bastiona, publicznego Load Balancera i Traffic Managera ograniczyło koszt oraz powierzchnię ataku.
3. VM `Standard_B1s` są oszczędnym wyborem dla środowiska demonstracyjnego.
4. Host zarządzający można deallokować poza wdrożeniami; zatrzymanie VM nie usuwa ich dysków.
5. Publiczne adresy backendów służą tylko do SNAT. NSG nie dopuszcza publicznego ruchu przychodzącego.

## Raport rzeczywisty

Rzeczywiste dane rozliczeniowe nie są publikowane. Można je wygenerować lokalnie:

```powershell
cd C:\Projects\terraform
.\azure-cost-report.ps1
```

Skrypt zapisuje pliki CSV w `docs/costs/`. Katalog jest ignorowany przez Git, a token Azure CLI pozostaje w pamięci procesu.

## Demonstracja kontroli kosztów

Status lub deallokację hosta zarządzającego można wykonać workflow `management-vm-control.yml`. Plan Terraform jest generowany przez GitHub Actions i nie wprowadza zmian bez osobno zatwierdzonego kroku `apply`.
