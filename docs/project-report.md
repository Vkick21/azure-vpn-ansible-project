# Sprawozdanie z projektu VKICKHAMSTER Helpdesk

## 1. Cel projektu

Celem projektu było przygotowanie funkcjonalnego środowiska Helpdesk w Microsoft Azure. Rozwiązanie miało łączyć publiczną usługę WWW, prywatny dostęp administracyjny przez VPN, automatyzację infrastruktury, bazę danych, kopie zapasowe i podstawowe mechanizmy bezpieczeństwa.

Projekt został przygotowany jako środowisko demonstracyjne, ale wykorzystuje rozwiązania spotykane w systemach produkcyjnych: Infrastructure as Code, segmentację sieci, wysoką dostępność warstwy aplikacyjnej, Managed Identity, Key Vault i centralny monitoring.

## 2. Zastosowane technologie

| Obszar | Technologia |
|---|---|
| Chmura | Microsoft Azure |
| Infrastruktura | Terraform |
| Konfiguracja serwerów | Ansible |
| System operacyjny | Ubuntu Server 24.04 LTS |
| Aplikacja | Python, Django, Gunicorn |
| Baza danych | PostgreSQL |
| Reverse proxy | Nginx |
| Tożsamość operatorów | Microsoft Entra ID, OpenID Connect |
| Pliki i kopie zapasowe | Azure Blob Storage |
| Sekrety | Azure Key Vault |
| Monitoring | Azure Monitor, Log Analytics |
| Certyfikat | Let's Encrypt |

## 3. Architektura

```mermaid
flowchart LR
    Internet["Użytkownik Internetu"] --> PublicLB["Publiczny Load Balancer"]
    VPNUser["Operator"] --> VPN["Azure VPN Gateway"]
    VPN --> PrivateLB["Prywatny Load Balancer 10.10.1.10"]
    Bastion["Azure Bastion"] --> App1["helpdesk01"]
    PublicLB --> App1
    PublicLB --> App2["helpdesk02"]
    PrivateLB --> App1
    PrivateLB --> App2["helpdesk02"]
    App1 --> DB["PostgreSQL 10.10.5.4"]
    App2 --> DB
    App1 --> Storage["Azure Storage"]
    App2 --> Storage
    DB --> Storage
    App1 --> KeyVault["Azure Key Vault"]
    App2 --> KeyVault
    Entra["Microsoft Entra ID"] --> App1
    Entra --> App2
```

Warstwa aplikacyjna składa się z dwóch małych VM `Standard_B1s`. Publiczny Load Balancer obsługuje formularz zgłoszeniowy, a oddzielny prywatny Load Balancer udostępnia panel operatora użytkownikom połączonym przez VPN.

PostgreSQL działa na osobnej VM `Standard_B1s` w dedykowanej podsieci. Serwer bazy nie ma publicznego adresu IP.

## 4. Plan adresacji

| Segment | Zakres |
|---|---|
| VNet | 10.10.0.0/16 |
| Aplikacja | 10.10.1.0/24 |
| Zarządzanie | 10.10.2.0/24 |
| GatewaySubnet | 10.10.3.0/27 |
| AzureBastionSubnet | 10.10.4.0/26 |
| Baza danych | 10.10.5.0/24 |
| Klienci VPN | 172.20.200.0/24 |

## 5. Routing i zabezpieczenia sieci

Środowisko korzysta z tras systemowych Azure. Trasy `VnetLocal` odpowiadają za komunikację podsieci, a trasa bramy wirtualnej obsługuje klientów Point-to-Site. W projekcie nie ma NVA ani Azure Firewall, dlatego nie zastosowano sztucznej trasy UDR kierującej ruch do nieistniejącego urządzenia.

NSG warstwy aplikacyjnej realizuje następujące zasady:

- SSH tylko z puli VPN i podsieci Bastiona;
- HTTP/HTTPS z Internetu dla publicznego formularza;
- HTTP/HTTPS z VPN dla panelu operatora;
- sonda Azure Load Balancer na porcie 80;
- PostgreSQL wychodzący wyłącznie do `10.10.5.4:5432`;
- ruch WWW wychodzący tylko na portach 80/443;
- blokada pozostałej komunikacji bocznej w VNet.

NSG bazy danych zezwala na PostgreSQL wyłącznie z podsieci aplikacji oraz na SSH z VPN/Bastionu. Pozostały ruch inicjowany z VNet jest blokowany.

Szczegóły znajdują się w `docs/network-security.md`.

## 6. VPN i panel operatora

Azure VPN Gateway udostępnia połączenie Point-to-Site z uwierzytelnianiem certyfikatem. Klient otrzymuje adres z puli `172.20.200.0/24`.

Publiczny DNS wskazuje publiczny Load Balancer. Komputer operatora po zestawieniu VPN mapuje tę samą nazwę na prywatny adres `10.10.1.10`. Pozwala to zachować prawidłową nazwę certyfikatu HTTPS i URI callbacku Entra ID.

Nginx dodatkowo blokuje publiczny dostęp do `/operator/`, `/oidc/` i `/admin/`. Samo poznanie adresu panelu nie wystarcza do jego otwarcia.

## 7. Aplikacja Helpdesk

Publiczny formularz umożliwia podanie adresu e-mail, tytułu, opisu, priorytetu i załącznika. Zgłoszenie jest zapisywane w PostgreSQL, a załącznik trafia do prywatnego kontenera Azure Storage.

Panel operatora umożliwia:

- wyświetlanie i filtrowanie zgłoszeń;
- otwieranie szczegółów zgłoszenia;
- przypisanie operatora;
- zmianę statusu i priorytetu;
- dodawanie komentarzy wewnętrznych;
- utworzenie nowego zgłoszenia;
- wylogowanie operatora.

Operatorzy logują się przez Microsoft Entra ID. Dostęp otrzymują wyłącznie członkowie grupy `VKICKHAMSTER Helpdesk Operators`. Awaryjne konto lokalne może być użyte, gdy Entra ID jest niedostępne.

## 8. Baza danych i kopie zapasowe

PostgreSQL działa w prywatnej podsieci. Parametry pamięci zostały ograniczone dla VM z 1 GB RAM. Dostęp sieciowy do portu 5432 mają wyłącznie serwery aplikacyjne.

Backup wykonywany jest codziennie przez timer systemd. Skrypt tworzy `pg_dump`, wysyła go do prywatnego kontenera `backups` w Azure Storage, usuwa kopię lokalną i utrzymuje 14-dniową retencję. Dostęp do Storage odbywa się przez Managed Identity, bez kluczy zapisanych na serwerze.

## 9. Sekrety i certyfikaty

Hasło bazy, klucz Django, hasło awaryjnego administratora i sekret klienta Entra są przechowywane w Azure Key Vault. VM odczytują je przez System Assigned Managed Identity.

Nginx obsługuje HTTPS z certyfikatem Let's Encrypt. Jeden backend odnawia certyfikat, zapisuje go w prywatnym Storage, a oba serwery synchronizują wspólną kopię.

## 10. Automatyzacja

Terraform zarządza zasobami Azure i stanem zdalnym. Ansible odpowiada za instalację oraz konfigurację Nginx, Django, PostgreSQL, HTTPS i backupu.

Najważniejsze zasady automatyzacji:

- plan Terraform jest analizowany przed wdrożeniem;
- kod aplikacji może zostać wdrożony bez migracji bazy;
- playbooki są idempotentne;
- sekrety nie są przechowywane w repozytorium;
- komentarze w plikach konfiguracji opisują cel najważniejszych elementów.

## 11. Testy odbiorcze

Po wdrożeniu wykonano następujące testy:

| Test | Wynik |
|---|---|
| Publiczny formularz HTTPS | 200 |
| Publiczny panel operatora | 403 |
| Panel operatora przez VPN | 302 do logowania |
| Entra ID przez VPN | 302 do Microsoft Login |
| SSH/Ansible do wszystkich VM | poprawny |
| Połączenie obu backendów z PostgreSQL | poprawne |
| Usługi Django, Nginx i PostgreSQL | aktywne |
| DNS z wszystkich VM | poprawny |
| HTTPS wychodzący z wszystkich VM | poprawny |
| Testy Django | 11/11 |
| Końcowy plan Terraform | No changes |

Testy sieciowe po zmianach NSG nie wprowadzały danych do produkcyjnej bazy.

## 12. Kosztorys

Rzeczywisty koszt miesiąc-do-daty w chwili wykonania raportu wynosił `<LOCAL_COST>`. Ostatnia pełna doba kosztowała `<LOCAL_DAILY_COST>`. Przewidywany koszt pracy przez cały miesiąc wynosi około `235–300 EUR`.

Największe składniki kosztu to Azure Bastion i VPN Gateway. VM `Standard_B1s` pozostają oszczędne, jednak zatrzymanie VM nie zatrzymuje opłat za bramę i Bastion.

Pełny kosztorys oraz dane CSV znajdują się w `docs/cost-estimate.md` i `docs/costs/`.

## 13. Ograniczenia i dalszy rozwój

- brak dedykowanej domeny; używana jest bezpłatna nazwa Azure;
- brak Azure Firewall/NVA, dlatego routing opiera się na trasach systemowych i NSG;
- Bastion i VPN Gateway generują wysoki koszt stały;
- PostgreSQL działa na pojedynczej VM i nie zapewnia wysokiej dostępności bazy;
- system powiadomień e-mail nie został jeszcze dodany;
- raport kosztów wymaga aktywnej sesji Azure CLI.

Możliwe rozszerzenia to powiadomienia e-mail, SLA zgłoszeń, historia audytowa, dashboard operatora, alerty Azure Monitor, prywatne endpointy Storage/Key Vault i automatyczne testy CI.

## 14. Podsumowanie

Projekt realizuje kompletny przepływ: publiczny użytkownik wysyła zgłoszenie, dane trafiają do PostgreSQL i Azure Storage, a operator po VPN loguje się przez Entra ID i obsługuje zgłoszenie. Infrastruktura, konfiguracja, bezpieczeństwo, kopie zapasowe i kosztorys są odtwarzalne z repozytorium.