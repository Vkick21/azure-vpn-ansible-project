param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Add", "Remove", "Status")]
    [string]$Action,

    [string]$Domain = $env:HELPDESK_FQDN,

    [string]$PrivateIp = $env:HELPDESK_PRIVATE_IP
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Domain -or -not $PrivateIp) {
    throw "Brakuje HELPDESK_FQDN lub HELPDESK_PRIVATE_IP."
}

$HostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"

$Principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
$IsAdmin = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if ($Action -ne "Status" -and -not $IsAdmin) {
    throw "Uruchom PowerShell jako administrator."
}

if ($Action -eq "Status") {
    Write-Host "Domena: $Domain"
    Write-Host "Oczekiwany prywatny adres: $PrivateIp"
    Resolve-DnsName $Domain -Type A
    Test-NetConnection $PrivateIp -Port 443
    exit
}

# Usuwamy tylko wpis tej aplikacji i nie zmieniamy pozostalych linii hosts.
$CurrentLines = Get-Content -LiteralPath $HostsPath
$RemainingLines = $CurrentLines | Where-Object {
    $_ -notmatch [regex]::Escape($Domain)
}

if ($Action -eq "Add") {
    $RemainingLines += $PrivateIp + [char]9 + $Domain + " # VKICKHAMSTER operator przez VPN"
    Write-Host "Dodano prywatny dostep operatora przez VPN."
}
else {
    Write-Host "Usunieto prywatne mapowanie. Domena wroci do publicznego adresu."
}

Set-Content -LiteralPath $HostsPath -Value $RemainingLines -Encoding ascii
Clear-DnsClientCache