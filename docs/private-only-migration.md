# Migracja Helpdesku do dostepu tylko przez VPN

## Cel

- jeden wewnetrzny Load Balancer `10.10.1.10`;
- formularz i panel dostepne tylko po VPN;
- brak publicznego IP aplikacji;
- brak Bastiona po potwierdzeniu dostepu przez runner i VPN;
- VPN Gateway pozostaje aktywny.

## Plan kontrolny

```powershell
. .\config.local.ps1
.\env.ps1 -Action private-plan
```

Plan ma usuwac publiczny LB, jego reguly, publiczne IP aplikacji, Traffic
Manager i Bastion. Nie moze usuwac VPN Gateway, trzech VM, dyskow, Storage,
Key Vault ani bazy PostgreSQL.

## DNS i HTTPS

Po migracji klient VPN kieruje obie nazwy Helpdesku na `10.10.1.10` przez
`operator-vpn-access.ps1`. Aktualny certyfikat pozostaje wazny, ale przed jego
wygasnieciem trzeba wdrozyc certyfikat prywatnej CA albo kontrolowana metode
odnawiania DNS-01. Publiczne HTTP-01 przestanie byc dostepne po usunieciu
publicznego Load Balancera.

## Warunki wykonania apply

1. Runner GitHub zwraca status online.
2. Ansible ping dziala z `ansible-mgmt` do wszystkich trzech VM.
3. Istnieje aktualny backup PostgreSQL i stanu Terraform.
4. Plan nie zawiera usuniecia danych ani VPN Gateway.
5. Uzytkownik osobno zatwierdzil apply.
