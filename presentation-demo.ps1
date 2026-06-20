param(
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

if (-not $env:HELPDESK_FQDN) {
    throw "Brakuje HELPDESK_FQDN w config.local.ps1."
}

$PublicUrl = "https://$($env:HELPDESK_FQDN)/"
$OperatorUrl = "https://$($env:HELPDESK_FQDN)/operator/"

Write-DemoHeader "VKICKHAMSTER Helpdesk - scenariusz prezentacji"
Write-Host "Skrypt jest przewodnikiem i nie wykonuje terraform apply." -ForegroundColor Magenta
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
    -Explanation "Publiczny Load Balancer blokuje panel operatora kodem 403." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove",
        "Otworz $OperatorUrl"
    ) `
    -Expected "Formularz nadal dziala, ale panel operatora zwraca 403."

Write-DemoStep `
    -Number 4 `
    -Title "Polaczenie VPN" `
    -Explanation "Polacz profil vnet-helpdesk w Azure VPN Client. Dopiero VPN daje trase do prywatnego Load Balancera." `
    -Commands @(
        "Test-NetConnection 10.10.1.10 -Port 443",
        ".\operator-vpn-access.ps1 -Action Add",
        ".\operator-vpn-access.ps1 -Action Status"
    ) `
    -Expected "TcpTestSucceeded ma wartosc True, a domena wskazuje 10.10.1.10."

Write-DemoStep `
    -Number 5 `
    -Title "Logowanie Microsoft Entra ID" `
    -Explanation "Operator musi nalezec do grupy Entra ID i zalogowac sie przez prywatny panel po VPN." `
    -Commands @(
        ".\entra-operators.ps1 -Action List",
        "Otworz $OperatorUrl"
    ) `
    -Expected "Po logowaniu widoczny jest panel i czytelna nazwa operatora."

if ($OpenPages) {
    Start-Process $OperatorUrl
}

Write-DemoStep `
    -Number 6 `
    -Title "Obsluga zgloszenia" `
    -Explanation "W panelu odnajdujemy ticket z kroku 2, przypisujemy operatora, dodajemy komentarz i zmieniamy status." `
    -Commands @(
        "Filtruj zgloszenia po tytule lub adresie e-mail.",
        "Zmien status: Nowe -> W realizacji -> Rozwiazane."
    ) `
    -Expected "Historia i aktualny stan zgloszenia sa zapisane w PostgreSQL."

Write-DemoStep `
    -Number 7 `
    -Title "Automatyzacja Ansible" `
    -Explanation "Ansible potwierdza dostep do wszystkich VM i zarzadza grupa operatorow." `
    -Commands @(
        'wsl bash -lc "cd /mnt/c/Projects/terraform/ansible && ansible all -i inventory.ini -m ping"',
        'wsl bash -lc "cd /mnt/c/Projects/terraform/ansible && ansible-playbook manage-operator.yml -e operator_action=list"'
    ) `
    -Expected "Wszystkie hosty odpowiadaja, a lista operatorow jest odczytana z Entra ID."

Write-DemoStep `
    -Number 8 `
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
    -Number 9 `
    -Title "Kontrola kosztow" `
    -Explanation "Plan oszczedny pokazuje usuniecie Bastiona i VPN Gateway, ale nie wykonuje zmian." `
    -Commands @(
        ".\env.ps1 -Action cost-plan"
    ) `
    -Expected "Terraform pokazuje plan oszczednosci bez wykonania apply."

Write-DemoStep `
    -Number 10 `
    -Title "Zakonczenie prezentacji" `
    -Explanation "Usuwamy tylko lokalne mapowanie domeny. Aplikacja, konta i dane pozostaja bez zmian." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove"
    ) `
    -Expected "Publiczny formularz dziala, a panel operatora ponownie jest blokowany publicznie."

Write-DemoHeader "Koniec scenariusza"
Write-Host "Najwazniejszy przeplyw: formularz -> CAPTCHA -> VPN -> Entra ID -> obsluga ticketu."
