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

function Set-HostsFileWithRetry {
    param(
        [string[]]$Lines,
        [int]$Attempts = 10
    )

    for ($Attempt = 1; $Attempt -le $Attempts; $Attempt++) {
        try {
            Set-Content -LiteralPath $HostsPath -Value $Lines -Encoding ascii
            return
        }
        catch [System.IO.IOException] {
            if ($Attempt -eq $Attempts) {
                throw
            }
            Start-Sleep -Milliseconds 500
        }
    }
}

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

if ($Action -eq "Add") {
    $PrivateEndpointAvailable = Test-NetConnection `
        -ComputerName $PrivateIp `
        -Port 443 `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue

    if (-not $PrivateEndpointAvailable) {
        throw "Brak polaczenia z prywatnym adresem $PrivateIp. Najpierw polacz profil vnet-helpdesk w Azure VPN Client."
    }
}

# Usuwamy tylko wpis tej aplikacji i nie zmieniamy pozostalych linii hosts.
$CurrentLines = Get-Content -LiteralPath $HostsPath
$RemainingLines = $CurrentLines | Where-Object {
    $_ -notmatch [regex]::Escape($Domain)
}

if ($Action -eq "Add") {
    $RemainingLines += $PrivateIp + [char]9 + $Domain + " # VKICKHAMSTER operator przez VPN"
}

Set-HostsFileWithRetry -Lines $RemainingLines
Clear-DnsClientCache

if ($Action -eq "Add") {
    Write-Host "Dodano prywatny dostep operatora przez VPN."
}
else {
    Write-Host "Usunieto prywatne mapowanie. Domena wroci do publicznego adresu."
}
