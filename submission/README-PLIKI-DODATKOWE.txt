VKICKHAMSTER Helpdesk - pliki dodatkowe
=======================================

Autor: Jan Michalak
E-mail akademicki: 110997@student.san.edu.pl
Repozytorium: https://github.com/Vkick21/azure-vpn-ansible-project

Pakiet zawiera niewrazliwa kopie kodu, konfiguracji i dokumentacji projektu.
Finalna usluga Helpdesk jest dostepna wylacznie po polaczeniu VPN.

Zawartosc pakietu
-----------------

1. Terraform/
   Definicje infrastruktury Azure: VNet, podsieci, NSG, trzy VM robocze,
   jeden prywatny Load Balancer, VPN Gateway, Storage, Key Vault i monitoring.
   Podkatalog bootstrap opisuje osobna VM ansible-mgmt.

2. Ansible/
   Inventory i playbooki konfigurujace Django, PostgreSQL, Nginx, HTTPS,
   backup, testy oraz czlonkostwo operatorow w grupie Microsoft Entra ID.

3. GitHub-Actions/
   Workflow Terraform Plan, chroniony Terraform Apply, wdrozenia Ansible,
   CI oraz uruchamianie i deallokacja VM ansible-mgmt.

4. PowerShell/
   Skrypty sterowania VM, mapowania prywatnych nazw Helpdesk, zarzadzania
   operatorami Entra ID, raportu kosztow i eksportu dowodow projektu.

5. Aplikacja-Django/
   Kod aplikacji Helpdesk, formularz z reCAPTCHA v2, panel operatora,
   integracja Entra ID, obsluga zalacznikow i testy jednostkowe.

6. Dokumentacja/
   Opis architektury, bezpieczenstwa sieci, kosztow, GitHub runnera i testow.

7. LINKI-ZEWNETRZNE.txt
   Repozytorium, adresy uslugi oraz oficjalna dokumentacja technologii.

Architektura finalna
--------------------

- dwa serwery Django Standard_B1s;
- jeden serwer PostgreSQL Standard_B1s;
- jedna VM ansible-mgmt Standard_B1s jako prywatny runner GitHub Actions;
- jeden prywatny Azure Load Balancer;
- Azure VPN Gateway VpnGw1AZ;
- brak Azure Bastion, Traffic Manager i publicznego Load Balancera;
- Terraform i Ansible wykonywane z GitHub Actions bez WSL;
- Terraform Apply wymaga jawnego potwierdzenia.

Celowo pominiete dane
---------------------

- config.local.ps1 i pliki *.tfvars;
- stan Terraform i zapisane plany;
- prywatne certyfikaty, klucze SSH i pliki PFX/PEM;
- hasla, tokeny oraz sekrety reCAPTCHA, Entra ID, Django i PostgreSQL;
- lokalne media aplikacji i eksporty kosztow z identyfikatorami subskrypcji;
- katalog .git i lokalne katalogi robocze narzedzi.

Bezpieczna demonstracja
-----------------------

1. Polacz VPN vnet-helpdesk.
2. Uruchom runner workflow management-vm-control.yml, akcja start.
3. Uruchom terraform-plan.yml albo ansible-deploy.yml.
4. Po demonstracji zdeallokuj runner akcja stop.

Nie uruchamiaj Terraform Apply bez sprawdzenia planu i osobnej zgody.
