# Routing i zabezpieczenia sieci VKICKHAMSTER

## Segmentacja

| Segment | Zakres | Przeznaczenie |
|---|---|---|
| Aplikacja | 10.10.1.0/24 | Dwa serwery Django i prywatny Load Balancer |
| Zarządzanie | 10.10.2.0/24 | VM runnera GitHub Actions |
| Gateway | 10.10.3.0/24 | Azure VPN Gateway |
| Zarezerwowany | 10.10.4.0/26 | Pusta podsieć po usuniętym Bastionie |
| Baza danych | 10.10.5.0/24 | Prywatny PostgreSQL |
| Klienci VPN | 172.20.200.0/24 | Komputery operatorów |

## Routing

Projekt używa tras systemowych Azure. Komunikacja wewnątrz VNet korzysta z `VnetLocal`, a ruch klientów Point-to-Site jest propagowany przez `VirtualNetworkGateway`. Nie zastosowano UDR, ponieważ środowisko nie zawiera NVA ani Azure Firewall.

Backendy mają po jednym publicznym IP służącym wyłącznie do ruchu wychodzącego SNAT. Nie istnieją reguły NSG dopuszczające publiczny ruch przychodzący.

## Reguły NSG

Warstwa aplikacji przyjmuje:

- SSH z puli VPN oraz z hosta zarządzającego;
- HTTP/HTTPS z puli VPN przez prywatny Load Balancer;
- sondę Azure Load Balancer;
- ruch do PostgreSQL na TCP/5432;
- wymagany ruch wychodzący HTTPS, DNS i do usług Azure.

Baza danych przyjmuje PostgreSQL wyłącznie z podsieci aplikacji oraz SSH z VPN lub hosta zarządzającego. Pozostały niepożądany ruch boczny jest blokowany.

## Weryfikacja

```powershell
az network nic show-effective-route-table --resource-group rg-helpdesk-prod --name nic-helpdesk01 --output table
az network nic list-effective-nsg --resource-group rg-helpdesk-prod --name nic-helpdesk01 --output json
az network nic list-effective-nsg --resource-group rg-helpdesk-prod --name nic-helpdesk-db01 --output json
```

Po zmianie należy sprawdzić dostęp do Helpdesk przez VPN, brak dostępu bez VPN, prywatny health check, połączenie z PostgreSQL oraz backup do Storage.
