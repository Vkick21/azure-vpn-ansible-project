param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Explain", "Login", "List", "Add", "Remove")]
    [string]$Action,

    [ValidatePattern('^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')]
    [string]$UserPrincipalName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot "config.local.ps1"

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host ("=" * 68) -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 68) -ForegroundColor DarkCyan
}

function Show-Explanation {
    Write-Section "WSL i Ansible - zarzadzanie operatorami"
    Write-Host "WSL to Windows Subsystem for Linux."
    Write-Host "Pozwala uruchamiac narzedzia Linux, takie jak Ansible, na Windows."
    Write-Host ""
    Write-Host "Wejscie do WSL:" -ForegroundColor Green
    Write-Host "  wsl" -ForegroundColor White
    Write-Host ""
    Write-Host "Wyjscie z WSL do PowerShell:" -ForegroundColor Green
    Write-Host "  exit" -ForegroundColor White
    Write-Host ""
    Write-Host "Katalog projektu widziany z WSL:" -ForegroundColor Green
    Write-Host "  /mnt/c/Projects/terraform/ansible" -ForegroundColor White
    Write-Host ""
    Write-Host "Logowanie Azure CLI wewnatrz WSL:" -ForegroundColor Green
    Write-Host '  az login --tenant "$ENTRA_TENANT_ID"' -ForegroundColor White
    Write-Host ""
    Write-Host "Playbook zmienia czlonkostwo w grupie Entra ID." -ForegroundColor Yellow
    Write-Host "Nie tworzy hasel i nie zapisuje sekretow w repozytorium."
    Write-Host "Ponowne dodanie tego samego operatora nie tworzy duplikatu."
    Write-Host ""
    Write-Host "Przyklady:" -ForegroundColor Green
    Write-Host "  .\operator-ansible-demo.ps1 -Action Login"
    Write-Host "  .\operator-ansible-demo.ps1 -Action List"
    Write-Host '  .\operator-ansible-demo.ps1 -Action Add -UserPrincipalName "user@example.com"'
    Write-Host '  .\operator-ansible-demo.ps1 -Action Remove -UserPrincipalName "user@example.com"'
}

if ($Action -eq "Explain") {
    Show-Explanation
    exit
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Brakuje config.local.ps1. Utworz go na podstawie config.example.ps1."
}

. $ConfigPath

if (-not $env:ENTRA_TENANT_ID -or -not $env:ENTRA_OPERATOR_GROUP_ID) {
    throw "Brakuje ENTRA_TENANT_ID lub ENTRA_OPERATOR_GROUP_ID."
}

$requiredWslVariables = @("ENTRA_TENANT_ID", "ENTRA_OPERATOR_GROUP_ID")
$existingWslVariables = @()
if ($env:WSLENV) {
    $existingWslVariables = $env:WSLENV -split ":"
}
$env:WSLENV = (($existingWslVariables + $requiredWslVariables) | Select-Object -Unique) -join ":"

wsl.exe --status | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "WSL nie jest dostepny. Uruchom wsl --install jako administrator."
}

if ($Action -eq "Login") {
    Write-Section "Logowanie Azure CLI wewnatrz WSL"
    Write-Host 'Wykonywana komenda: az login --tenant "$ENTRA_TENANT_ID"'
    wsl.exe bash -lc 'az login --tenant "$ENTRA_TENANT_ID"'
    exit $LASTEXITCODE
}

if ($Action -in @("Add", "Remove") -and -not $UserPrincipalName) {
    throw "Dla akcji $Action podaj -UserPrincipalName."
}

$actionLower = $Action.ToLowerInvariant()
$playbookCommand = "cd /mnt/c/Projects/terraform/ansible && ansible-playbook -i inventory.ini manage-operator.yml -e operator_action=$actionLower"

if ($UserPrincipalName) {
    $playbookCommand += " -e operator_upn='$UserPrincipalName'"
}

Write-Section ("Ansible - akcja {0}" -f $Action)
Write-Host "WSL uruchamia playbook manage-operator.yml."
Write-Host ("Konto: {0}" -f $(if ($UserPrincipalName) { $UserPrincipalName } else { "lista operatorow" }))
Write-Host ""

wsl.exe bash -lc 'az account show --output none'
if ($LASTEXITCODE -ne 0) {
    throw "Brak sesji Azure CLI w WSL. Najpierw uruchom -Action Login."
}

wsl.exe bash -lc $playbookCommand
exit $LASTEXITCODE
