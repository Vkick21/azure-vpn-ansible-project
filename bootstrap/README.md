# VM zarzadzajaca VKICKHAMSTER

Ten stos tworzy tylko VM `ansible-mgmt` i jej uprawnienia. Uzywa osobnego
klucza stanu `bootstrap.tfstate`, dlatego glowny Terraform Helpdesku nie moze
restartowac ani usuwac runnera.

## Bezpieczna kolejnosc

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap fmt -check
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan
```

`terraform apply` wymaga osobnej akceptacji. Po utworzeniu VM nalezy polaczyc
VPN, zalogowac sie przez SSH na `10.10.2.10` i zarejestrowac runner GitHub.

Publiczny adres VM sluzy do polaczen wychodzacych. Domyslne reguly NSG blokuja
SSH z Internetu, a regula projektu dopuszcza port 22 tylko z puli VPN.
