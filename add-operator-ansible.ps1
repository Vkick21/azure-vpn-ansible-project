param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')]
    [string]$UserPrincipalName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot "config.local.ps1"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Brakuje config.local.ps1."
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
    throw "WSL nie jest dostepny."
}

wsl.exe bash -lc 'az account show --output none'
if ($LASTEXITCODE -ne 0) {
    wsl.exe bash -lc 'az login --tenant "$ENTRA_TENANT_ID"'
    if ($LASTEXITCODE -ne 0) {
        throw "Logowanie Azure CLI w WSL nie powiodlo sie."
    }
}

$command = "cd /mnt/c/Projects/terraform/ansible && ansible-playbook -i inventory.ini manage-operator.yml -e operator_action=add -e operator_upn='$UserPrincipalName'"
wsl.exe bash -lc $command
exit $LASTEXITCODE
