param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')]
    [string]$UserPrincipalName,

    [SecureString]$PfxPassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot "config.local.ps1"
$PackagesRoot = Join-Path $ProjectRoot "operator-packages"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Brakuje config.local.ps1."
}

. $ConfigPath

if (-not $env:HELPDESK_FQDN -or -not $env:HELPDESK_PRIVATE_IP) {
    throw "Brakuje HELPDESK_FQDN lub HELPDESK_PRIVATE_IP."
}

if (-not $PfxPassword) {
    $PfxPassword = Read-Host "Podaj haslo chroniace PFX operatora" -AsSecureString
}

# Najpierw nadajemy uprawnienie do aplikacji przez grupe Entra ID.
& (Join-Path $ProjectRoot "add-operator-ansible.ps1") `
    -UserPrincipalName $UserPrincipalName
if ($LASTEXITCODE -ne 0) {
    throw "Dodanie operatora przez Ansible nie powiodlo sie."
}

$rootCertificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object {
        $_.Subject -eq "CN=AzureVPNRootCert" -and
        $_.HasPrivateKey -and
        $_.NotAfter -gt (Get-Date)
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $rootCertificate) {
    throw "Nie znaleziono waznego AzureVPNRootCert z kluczem prywatnym."
}

$safeOperatorName = $UserPrincipalName -replace '[^A-Za-z0-9._-]', '_'
$certificateSubject = "CN=VKICKHAMSTER-$safeOperatorName"
$clientCertificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object {
        $_.Subject -eq $certificateSubject -and
        $_.Issuer -eq $rootCertificate.Subject -and
        $_.HasPrivateKey -and
        $_.NotAfter -gt (Get-Date)
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $clientCertificate) {
    $clientCertificate = New-SelfSignedCertificate `
        -Type Custom `
        -Subject $certificateSubject `
        -KeySpec Signature `
        -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 `
        -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -Signer $rootCertificate `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$packageDirectory = Join-Path $PackagesRoot "$safeOperatorName-$timestamp"
New-Item -ItemType Directory -Path $packageDirectory -Force | Out-Null

$pfxPath = Join-Path $packageDirectory "VKICKHAMSTER-$safeOperatorName.pfx"
$cerPath = Join-Path $packageDirectory "VKICKHAMSTER-$safeOperatorName.cer"
Export-PfxCertificate `
    -Cert "Cert:\CurrentUser\My\$($clientCertificate.Thumbprint)" `
    -FilePath $pfxPath `
    -Password $PfxPassword `
    -ChainOption EndEntityCertOnly | Out-Null
Export-Certificate `
    -Cert "Cert:\CurrentUser\My\$($clientCertificate.Thumbprint)" `
    -FilePath $cerPath | Out-Null

# Uzywamy osobnego katalogu rozszerzen, aby uszkodzone dodatki Azure CLI
# nie blokowaly pobrania profilu VPN.
$env:AZURE_EXTENSION_DIR = Join-Path $env:LOCALAPPDATA "VKICKHAMSTER\azure-cli-extensions"
New-Item -ItemType Directory -Path $env:AZURE_EXTENSION_DIR -Force | Out-Null

az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
    az login --tenant $env:ENTRA_TENANT_ID | Out-Null
}

$resourceGroup = terraform "-chdir=$ProjectRoot" output -raw resource_group_name
if ($LASTEXITCODE -ne 0 -or -not $resourceGroup) {
    throw "Nie mozna odczytac grupy zasobow z Terraform."
}
$resourceGroup = $resourceGroup.Trim()

$gatewayName = az network vnet-gateway list `
    --resource-group $resourceGroup `
    --query "[0].name" `
    --output tsv
if ($LASTEXITCODE -ne 0 -or -not $gatewayName) {
    throw "Nie znaleziono VPN Gateway."
}
$gatewayName = $gatewayName.Trim()

$profileUrl = az network vnet-gateway vpn-client generate `
    --resource-group $resourceGroup `
    --name $gatewayName `
    --processor-architecture Amd64 `
    --output tsv
if ($LASTEXITCODE -ne 0 -or -not $profileUrl) {
    throw "Nie udalo sie wygenerowac profilu VPN."
}
$profileUrl = $profileUrl.Trim()

$profileZip = Join-Path $packageDirectory "vpn-client-profile.zip"
$profileDirectory = Join-Path $packageDirectory "vpn-client-profile"
Invoke-WebRequest -Uri $profileUrl -OutFile $profileZip -UseBasicParsing
Expand-Archive -LiteralPath $profileZip -DestinationPath $profileDirectory
Remove-Item -LiteralPath $profileZip

Copy-Item `
    -LiteralPath (Join-Path $ProjectRoot "operator-vpn-access.ps1") `
    -Destination $packageDirectory

$operatorConfig = @"
`$env:HELPDESK_FQDN = "$($env:HELPDESK_FQDN)"
`$env:HELPDESK_PRIVATE_IP = "$($env:HELPDESK_PRIVATE_IP)"
"@
Set-Content `
    -LiteralPath (Join-Path $packageDirectory "operator-config.ps1") `
    -Value $operatorConfig `
    -Encoding ascii

$instructions = @"
VKICKHAMSTER Helpdesk - pakiet operatora
=========================================

Operator: $UserPrincipalName

1. Zainstaluj plik PFX w magazynie Biezacy uzytkownik, Osobisty.
2. Haslo PFX odbierz osobnym, bezpiecznym kanalem.
3. W Azure VPN Client zaimportuj plik azurevpnconfig.xml z katalogu
   vpn-client-profile\AzureVPN.
4. Zamknij i ponownie uruchom Azure VPN Client, aby odswiezyc liste
   certyfikatow klienta.
5. Polacz profil vnet-helpdesk.
6. Uruchom PowerShell jako administrator i wykonaj:

   . .\operator-config.ps1
   .\operator-vpn-access.ps1 -Action Add

7. Otworz panel:
   https://$($env:HELPDESK_FQDN)/operator/

8. Zaloguj sie kontem: $UserPrincipalName

Po zakonczeniu pracy:

   .\operator-vpn-access.ps1 -Action Remove

PFX zawiera prywatny klucz. Nie wysylaj pakietu publicznym kanalem
i nie zapisuj go w repozytorium Git.
"@
Set-Content `
    -LiteralPath (Join-Path $packageDirectory "INSTRUKCJA-OPERATORA.txt") `
    -Value $instructions `
    -Encoding utf8

$packageZip = Join-Path $PackagesRoot "VKICKHAMSTER-operator-$safeOperatorName-$timestamp.zip"
Compress-Archive -Path (Join-Path $packageDirectory "*") -DestinationPath $packageZip

Write-Host "Operator zostal dodany do grupy Entra ID."
Write-Host "Utworzono indywidualny certyfikat VPN."
Write-Host "Pakiet operatora: $packageZip"
Write-Host "Przekaz haslo PFX osobnym kanalem."
