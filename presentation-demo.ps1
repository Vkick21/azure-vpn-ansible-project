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

$HelpdeskUrl = "https://$($env:HELPDESK_FQDN)/"
$OperatorUrl = "https://$($env:HELPDESK_OPERATOR_FQDN)/operator/"

Write-DemoHeader "VKICKHAMSTER Helpdesk - scenariusz prezentacji"
Write-Host "Skrypt jest przewodnikiem i nie wykonuje terraform apply." -ForegroundColor Magenta
Write-Host "Zdalny host operatora musi miec wczesniej profil i certyfikat VPN." -ForegroundColor Magenta
Write-Host "Konto demonstracyjne: $OperatorUpn"
Write-Host "Formularz po VPN: $HelpdeskUrl"
Write-Host "Panel po VPN:     $OperatorUrl"

Write-DemoStep `
    -Number 1 `
    -Title "Stan infrastruktury" `
    -Explanation "Pokazujemy trzy VM robocze oraz osobna VM ansible-mgmt dzialajaca jako runner GitHub Actions." `
    -Commands @(
        "terraform output",
        ".\env.ps1 -Action status",
        "az vm get-instance-view --resource-group rg-helpdesk-management --name ansible-mgmt --query instanceView.statuses[1].displayStatus --output tsv"
    ) `
    -Expected "Widoczne sa VM aplikacji i bazy, a runner ansible-mgmt ma stan online lub active."

Write-DemoStep `
    -Number 2 `
    -Title "Blokada Helpdesku bez VPN" `
    -Explanation "Formularz i panel korzystaja z prywatnego adresu Load Balancera i bez VPN nie sa osiagalne." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove",
        "Rozlacz profil vnet-helpdesk w Azure VPN Client.",
        "Test-NetConnection 10.10.1.10 -Port 443"
    ) `
    -Expected "TcpTestSucceeded ma wartosc False, a formularz i panel nie otwieraja sie."

Write-DemoStep `
    -Number 3 `
    -Title "Polaczenie VPN i prywatne nazwy" `
    -Explanation "Po zestawieniu VPN lokalne mapowanie kieruje obie nazwy Helpdesku na prywatny Load Balancer 10.10.1.10." `
    -Commands @(
        "W Azure VPN Client kliknij Polacz dla profilu vnet-helpdesk.",
        ".\operator-vpn-access.ps1 -Action Add",
        ".\operator-vpn-access.ps1 -Action Status"
    ) `
    -Expected "TcpTestSucceeded ma wartosc True, a obie domeny wskazuja 10.10.1.10."

Write-DemoStep `
    -Number 4 `
    -Title "Formularz i reCAPTCHA" `
    -Explanation "Po VPN uzytkownik wysyla zgloszenie. reCAPTCHA v2 ogranicza automatyczny spam." `
    -Commands @(
        "Otworz $HelpdeskUrl",
        "Sprobuj wyslac bez CAPTCHA, a potem z poprawna CAPTCHA."
    ) `
    -Expected "Pierwsza proba jest odrzucona, a druga tworzy zgloszenie."

if ($OpenPages) {
    Start-Process $HelpdeskUrl
}

Write-DemoStep `
    -Number 5 `
    -Title "Czlonkostwo operatora" `
    -Explanation "Pomocniczy skrypt Ansible idempotentnie dodaje UPN do grupy operatorow Entra ID. To operacja administracyjna, a wdrozenia infrastruktury nadal wykonuja workflowy GitHub Actions." `
    -Commands @(
        ".\add-operator-ansible.ps1 -UserPrincipalName `"$OperatorUpn`"",
        ".\entra-operators.ps1 -Action List"
    ) `
    -Expected "Konto jest widoczne w grupie VKICKHAMSTER Helpdesk Operators."

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
    -Explanation "W panelu odnajdujemy ticket z kroku 4, przypisujemy operatora, dodajemy komentarz i zmieniamy status." `
    -Commands @(
        "Filtruj zgloszenia po tytule lub adresie e-mail.",
        "Zmien status: Nowe -> W realizacji -> Rozwiazane."
    ) `
    -Expected "Historia i aktualny stan zgloszenia sa zapisane w PostgreSQL."

Write-DemoStep `
    -Number 8 `
    -Title "Weryfikacja przez Ansible na runnerze Azure" `
    -Explanation "Workflow uruchamia verify-helpdesk.yml na prywatnej VM ansible-mgmt, bez WSL i bez publicznego SSH." `
    -Commands @(
        "gh workflow run ansible-deploy.yml --repo Vkick21/azure-vpn-ansible-project -f playbook=verify-helpdesk.yml",
        "gh run list --repo Vkick21/azure-vpn-ansible-project --workflow ansible-deploy.yml --limit 3"
    ) `
    -Expected "PLAY RECAP pokazuje unreachable=0 i failed=0 dla wszystkich trzech hostow."

Write-DemoStep `
    -Number 9 `
    -Title "Walidacja Terraform" `
    -Explanation "GitHub Actions wykonuje walidacje i Terraform Plan na runnerze ansible-mgmt bez wprowadzania zmian w Azure." `
    -Commands @(
        "gh workflow run terraform-plan.yml --repo Vkick21/azure-vpn-ansible-project -f mode=private-only",
        "gh run list --repo Vkick21/azure-vpn-ansible-project --workflow terraform-plan.yml --limit 3"
    ) `
    -Expected "Workflow konczy sie sukcesem, a plan zwraca No changes."

Write-Host "UWAGA: Podczas prezentacji nie wykonuj terraform apply." -ForegroundColor Red

Write-DemoStep `
    -Number 10 `
    -Title "Kontrola kosztow" `
    -Explanation "Finalny wariant nie zawiera Bastiona, Traffic Managera ani publicznego Load Balancera. VPN pozostaje wymagany. Oba polecenia tylko pokazuja plan." `
    -Commands @(
        ".\env.ps1 -Action private-plan",
        ".\env.ps1 -Action cost-plan"
    ) `
    -Expected "Terraform potwierdza prywatny wariant i nie wykonuje apply."

Write-DemoStep `
    -Number 11 `
    -Title "Zakonczenie prezentacji" `
    -Explanation "Usuwamy lokalne mapowanie domeny. Opcjonalnie odbieramy testowemu kontu czlonkostwo w grupie operatorow." `
    -Commands @(
        ".\operator-vpn-access.ps1 -Action Remove",
        "Rozlacz profil vnet-helpdesk w Azure VPN Client.",
        ".\entra-operators.ps1 -Action Remove -UserPrincipalName `"$OperatorUpn`"  # opcjonalnie"
    ) `
    -Expected "Po rozlaczeniu VPN formularz i panel nie sa osiagalne, a dane zgloszen pozostaja bez zmian."

Write-DemoHeader "Koniec scenariusza"
Write-Host "Najwazniejszy przeplyw: VPN -> formularz -> CAPTCHA -> Entra ID -> obsluga ticketu."
