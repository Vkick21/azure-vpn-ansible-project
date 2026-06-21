param(
    [ValidatePattern('^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')]
    [string]$OperatorUpn = "user@example.com",

    [switch]$OpenPages,
    [switch]$NoPause
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot "config.local.ps1"

function Write-DemoHeader {
    param([string]$Text)

    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
}

function Write-DemoStep {
    param(
        [int]$Number,
        [string]$Title,
        [string]$Explanation,
        [string[]]$Commands,
        [string]$Expected
    )

    Write-Host ""
    Write-Host ("KROK {0}: {1}" -f $Number, $Title) -ForegroundColor Yellow
    Write-Host $Explanation
    Write-Host ""
    Write-Host "Komendy:" -ForegroundColor Green
    foreach ($Command in $Commands) {
        Write-Host ("  {0}" -f $Command) -ForegroundColor White
    }
    Write-Host ""
    Write-Host ("Oczekiwany wynik: {0}" -f $Expected) -ForegroundColor DarkGreen

    if (-not $NoPause) {
        [void](Read-Host "Nacisnij Enter, aby przejsc dalej")
    }
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Brakuje config.local.ps1. Utworz go na podstawie config.example.ps1."
}

. $ConfigPath

if (-not $env:HELPDESK_FQDN -or -not $env:HELPDESK_OPERATOR_FQDN) {
    throw "Brakuje HELPDESK_FQDN lub HELPDESK_OPERATOR_FQDN w config.local.ps1."
}

$PublicUrl = "https://$($env:HELPDESK_FQDN)/"
$OperatorUrl = "https://$($env:HELPDESK_OPERATOR_FQDN)/operator/"

Write-DemoHeader "VKICKHAMSTER Helpdesk - scenariusz prezentacji"
Write-Host "Skrypt jest przewodnikiem i nie wykonuje terraform apply." -ForegroundColor Magenta
Write-Host "Zdalny host operatora musi miec wczesniej profil i certyfikat VPN." -ForegroundColor Magenta
Write-Host "Konto demonstracyjne: $OperatorUpn"
Write-Host "Publiczny formularz: $PublicUrl"
Write-Host "Panel operatora:     $OperatorUrl"

Write-DemoStep `
    -Number 1 `
    -Title "Stan infrastruktury" `
    -Explanation "Pokazujemy zasoby zwracane przez Terraform i stan trzech maszyn." `
    -Commands @(
        "terraform output",
        ".\env.ps1 -Action status"
    ) `
    -Expected "Widoczne sa zasoby projektu oraz stan VM aplikacji i bazy."

Write-DemoStep `
    -Number 2 `
    -Title "Publiczny formularz i reCAPTCHA" `
    -Explanation "Formularz jest publiczny, ale utworzenie zgloszenia wymaga poprawnej reCAPTCHA v2." `
    -Commands @(
        "Otworz $PublicUrl",
        "Najpierw sprobuj wyslac bez CAPTCHA, a potem z poprawna CAPTCHA."
    ) `
    -Expected "Pierwsza proba jest odrzucona, a druga tworzy zgloszenie."

if ($OpenPages) {
    Start-Process $PublicUrl
}

Write-DemoStep `
    -Number 3 `
    -Title "Blokada panelu bez VPN" `
    -Explanation "Osobna publiczna nazwa operatora zwraca 403, a formularz pozostaje dostepny pod swoim adresem." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove",
        "Otworz $OperatorUrl"
    ) `
    -Expected "Formularz nadal dziala, ale panel operatora zwraca 403."

Write-DemoStep `
    -Number 4 `
    -Title "Dodanie operatora przez Ansible" `
    -Explanation "PowerShell przekazuje UPN do WSL, a Ansible idempotentnie dodaje konto do grupy operatorow Entra ID." `
    -Commands @(
        ".\add-operator-ansible.ps1 -UserPrincipalName `"$OperatorUpn`"",
        ".\entra-operators.ps1 -Action List"
    ) `
    -Expected "Konto jest widoczne w grupie VKICKHAMSTER Helpdesk Operators."

Write-DemoStep `
    -Number 5 `
    -Title "Zdalny host operatora i polaczenie VPN" `
    -Explanation "Na przygotowanym zdalnym hoscie polacz profil vnet-helpdesk. Host ma juz zainstalowany certyfikat i profil VPN." `
    -Commands @(
        "W Azure VPN Client kliknij Polacz dla profilu vnet-helpdesk.",
        "Test-NetConnection 10.10.1.10 -Port 443",
        ".\operator-vpn-access.ps1 -Action Add",
        ".\operator-vpn-access.ps1 -Action Status"
    ) `
    -Expected "TcpTestSucceeded ma wartosc True, a domena operatora wskazuje 10.10.1.10."

Write-DemoStep `
    -Number 6 `
    -Title "Logowanie Microsoft Entra ID" `
    -Explanation "Operator musi nalezec do grupy Entra ID i zalogowac sie przez prywatny panel po VPN." `
    -Commands @(
        "Otworz $OperatorUrl",
        "Zaloguj sie jako $OperatorUpn"
    ) `
    -Expected "Po logowaniu widoczny jest panel i czytelna nazwa operatora."

if ($OpenPages) {
    Start-Process $OperatorUrl
}

Write-DemoStep `
    -Number 7 `
    -Title "Obsluga zgloszenia" `
    -Explanation "W panelu odnajdujemy ticket z kroku 2, przypisujemy operatora, dodajemy komentarz i zmieniamy status." `
    -Commands @(
        "Filtruj zgloszenia po tytule lub adresie e-mail.",
        "Zmien status: Nowe -> W realizacji -> Rozwiazane."
    ) `
    -Expected "Historia i aktualny stan zgloszenia sa zapisane w PostgreSQL."

Write-DemoStep `
    -Number 8 `
    -Title "Kontrola serwerow przez Ansible" `
    -Explanation "Ansible potwierdza prywatny dostep SSH do wszystkich maszyn projektu." `
    -Commands @(
        'wsl bash -lc "cd /mnt/c/Projects/terraform/ansible && ansible all -i inventory.ini -m ping"'
    ) `
    -Expected "helpdesk01, helpdesk02 i helpdesk-db01 zwracaja SUCCESS."

Write-DemoStep `
    -Number 9 `
    -Title "Walidacja Terraform" `
    -Explanation "Sprawdzamy kod i plan bez wprowadzania zmian w Azure." `
    -Commands @(
        "terraform fmt -check -recursive",
        "terraform validate",
        ".\env.ps1 -Action plan"
    ) `
    -Expected "Konfiguracja jest poprawna, a plan najlepiej zwraca No changes."

Write-Host "UWAGA: Podczas prezentacji nie wykonuj terraform apply." -ForegroundColor Red

Write-DemoStep `
    -Number 10 `
    -Title "Kontrola kosztow" `
    -Explanation "Plan oszczedny pokazuje usuniecie Bastiona i VPN Gateway, ale nie wykonuje zmian." `
    -Commands @(
        ".\env.ps1 -Action private-plan",
        ".\env.ps1 -Action cost-plan"
    ) `
    -Expected "Terraform pokazuje wariant prywatny i oszczednosci bez wykonania apply."

Write-DemoStep `
    -Number 11 `
    -Title "Zakonczenie prezentacji" `
    -Explanation "Usuwamy lokalne mapowanie domeny. Opcjonalnie odbieramy testowemu kontu czlonkostwo w grupie operatorow." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove",
        ".\entra-operators.ps1 -Action Remove -UserPrincipalName `"$OperatorUpn`"  # opcjonalnie"
    ) `
    -Expected "Publiczny formularz dziala, panel jest blokowany publicznie, a dane zgloszen pozostaja bez zmian."

Write-DemoHeader "Koniec scenariusza"
Write-Host "Najwazniejszy przeplyw: formularz -> CAPTCHA -> VPN -> Entra ID -> obsluga ticketu."
