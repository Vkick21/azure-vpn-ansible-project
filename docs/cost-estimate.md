# Kosztorys Azure — VKICKHAMSTER Helpdesk

Data raportu: 20 czerwca 2026 r.
Region: West Europe
Grupa zasobów: `rg-helpdesk-prod`
Subskrypcja: Azure for Students

## Dane rzeczywiste

Koszt pobrano bezpośrednio z Azure Cost Management za pomocą skryptu `azure-cost-report.ps1`.

- koszt miesiąc-do-daty: **<LOCAL_COST>**;
- ostatnia pełna doba widoczna w raporcie: **<LOCAL_DAILY_COST>**;
- prosta projekcja 30-dniowa: około **234 EUR**;
- bezpieczny przedział planistyczny: **235–300 EUR miesięcznie**.

Przedział uwzględnia opóźnienie danych Cost Management, niepełny bieżący dzień, transfer oraz wzrost ilości logów i danych.

## Koszt według usług

| Usługa | Koszt miesiąc-do-daty |
|---|---:|
| Azure Bastion | 6,54 EUR |
| VPN Gateway | 6,11 EUR |
| Virtual Network | 0,58 EUR |
| Storage | 0,21 EUR |
| Key Vault | poniżej 0,01 EUR |
| Bandwidth | poniżej 0,01 EUR |
| Log Analytics | 0,00 EUR |
| Virtual Machines | 0,00 EUR |
| Load Balancer | 0,00 EUR |

Wartości `0,00 EUR` mogą wynikać z benefitów Azure for Students, bezpłatnych limitów albo opóźnienia naliczania. Nie oznaczają, że dana usługa pozostanie bezpłatna poza tą subskrypcją.

## Najważniejsze wnioski

1. Bastion i VPN Gateway generują prawie cały koszt środowiska.
2. Wyłączenie VM ogranicza koszt obliczeń, ale nie zatrzymuje naliczania za Bastion i VPN Gateway.
3. Trzy VM `Standard_B1s` są oszczędnym wyborem dla środowiska demonstracyjnego.
4. Usunięcie Bastiona poza prezentacjami da największą oszczędność, ale pozostawi administrację zależną od VPN.
5. VPN Gateway jest wymagany dla prywatnego panelu operatora, dlatego jego usunięcie zmieniłoby założenia projektu.

## Pliki danych

- `docs/costs/azure-cost-daily.csv` — koszt dzienny;
- `docs/costs/azure-cost-by-service.csv` — koszt według usług;
- `docs/costs/azure-resources.csv` — lista zasobów projektu.

Aktualizacja raportu:

```powershell
cd C:\Projects\terraform
.\azure-cost-report.ps1
```

Skrypt używa bieżącej sesji Azure CLI. Token dostępu pozostaje wyłącznie w pamięci procesu i nie jest zapisywany w repozytorium.