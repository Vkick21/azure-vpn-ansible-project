# Routing i zabezpieczenia sieci VKICKHAMSTER

## Segmentacja

| Segment | Zakres | Przeznaczenie |
|---|---|---|
| Aplikacja | 10.10.1.0/24 | Dwa serwery Django i oba load balancery |
| Zarządzanie | 10.10.2.0/24 | Zarezerwowany segment administracyjny |
| Gateway | 10.10.3.0/27 | Brama VPN |
| Bastion | 10.10.4.0/26 | Azure Bastion |
| Baza danych | 10.10.5.0/24 | Prywatny PostgreSQL |
| Klienci VPN | 172.20.200.0/24 | Komputery operatorów |

## Routing

Projekt używa tras systemowych Azure. Ruch pomiędzy podsieciami VNet korzysta z trasy `VnetLocal`, ruch operatorów jest propagowany przez `VirtualNetworkGateway`, a publiczne endpointy Azure i Internet korzystają z domyślnej trasy platformy.

Nie dodano sztucznej tablicy UDR, ponieważ w architekturze nie ma urządzenia NVA ani Azure Firewall, do którego należałoby skierować ruch. Redundantna trasa `0.0.0.0/0 -> Internet` nie zwiększyłaby bezpieczeństwa. Jeżeli projekt zostanie rozszerzony o firewall, UDR powinien kierować ruch wychodzący podsieci aplikacji i bazy do jego prywatnego adresu.

## Reguły NSG

Warstwa aplikacji przyjmuje:

- SSH tylko z VPN i Azure Bastion;
- HTTP/HTTPS z Internetu dla publicznego formularza;
- HTTP/HTTPS z puli VPN dla panelu operatora;
- sondę HTTP Azure Load Balancer;
- pozostały ruch inicjowany z VNet jest blokowany.

Serwery aplikacji mogą inicjować połączenie do PostgreSQL wyłącznie na TCP/5432. Ruch wychodzący do Internetu jest ograniczony do HTTP/HTTPS i DNS, a pozostała komunikacja boczna w VNet jest blokowana.

Baza danych przyjmuje PostgreSQL tylko z podsieci aplikacji oraz SSH z VPN/Bastionu. Pozostały ruch z VNet jest blokowany. Ruch wychodzący pozostawia DNS i HTTP/HTTPS potrzebne do aktualizacji oraz kopii zapasowych w Azure Storage.

## Weryfikacja tras i reguł

Efektywne trasy można wyeksportować poleceniem:

```powershell
az network nic show-effective-route-table --resource-group rg-helpdesk-prod --name nic-helpdesk01 --output table
```

Efektywne reguły NSG:

```powershell
az network nic list-effective-nsg --resource-group rg-helpdesk-prod --name nic-helpdesk01 --output json
az network nic list-effective-nsg --resource-group rg-helpdesk-prod --name nic-helpdesk-db01 --output json
```

Po każdej zmianie należy sprawdzić publiczny formularz, prywatny panel przez VPN, SSH z VPN, połączenie aplikacji z PostgreSQL oraz wykonanie backupu.