# Plan optymalizacji kosztow

Punkt odniesienia z kalkulatora projektu wynosi 353,34 USD miesiecznie przy
pracy przez 730 godzin. Najwieksze stale pozycje to Bastion i VPN Gateway.

## Zmiany docelowe

| Zmiana | Wplyw |
|---|---|
| Usuniecie Azure Bastion | Najwieksza oszczednosc, okolo 138,70 USD wedlug obecnego kosztorysu |
| Jeden prywatny Load Balancer | Mniej regul i brak publicznego modulu LB |
| Usuniecie publicznego IP aplikacji | Mniejszy koszt i brak publicznej powierzchni ataku |
| Usuniecie Traffic Manager | Uproszczenie DNS po przejsciu na prywatne mapowanie |
| Runner Standard_B1s | Niski koszt, szczegolnie przy deallokacji poza wdrozeniami |
| VPN Gateway pozostaje | Koszt wymagany przez nowe kryterium dostepu |
| Log Analytics 30 dni | Ograniczenie kosztu przechowywania i pozyskiwania logow |

Samo odjecie Bastiona i dodanie stale dzialajacego B1s daje konserwatywny
poziom ponizej okolo 225 USD miesiecznie przed uwzglednieniem dalszych
oszczednosci na publicznym LB. Runner uruchamiany tylko na czas workflow obniza
koszt compute jeszcze bardziej. Po migracji trzeba ponownie wyeksportowac
kalkulacje Azure, bo ceny i transfer zaleza od subskrypcji.

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
