param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "restart", "status", "plan", "private-plan", "cost-plan")]
    [string]$Action,

    [string]$ResourceGroup = "rg-helpdesk-prod"
)

Set-StrictMode -Version Latest

# Skrypt dziala zawsze wzgledem katalogu projektu.
Set-Location $PSScriptRoot

# Local environment values are intentionally ignored by Git.
$ConfigPath = Join-Path $PSScriptRoot "config.local.ps1"
if (Test-Path -LiteralPath $ConfigPath) {
    . $ConfigPath
}

# Baza uruchamia sie przed aplikacja i zatrzymuje jako ostatnia.
$AppVmNames = @("helpdesk01", "helpdesk02")
$DatabaseVmName = "helpdesk-db01"

switch ($Action)
{
    "start" {
        Write-Host "Starting database..."
        az vm start --resource-group $ResourceGroup --name $DatabaseVmName

        Write-Host "Starting application servers..."
        foreach ($VmName in $AppVmNames) {
            az vm start --resource-group $ResourceGroup --name $VmName
        }
    }

    "stop" {
        # Najpierw zatrzymujemy aplikacje, zeby nie zerwala polaczen do bazy.
        Write-Host "Stopping application servers..."
        foreach ($VmName in $AppVmNames) {
            az vm deallocate --resource-group $ResourceGroup --name $VmName
        }

        Write-Host "Stopping database..."
        az vm deallocate --resource-group $ResourceGroup --name $DatabaseVmName
        Write-Host "Compute stopped. Network + VPN preserved."
    }

    "restart" {
        # Kolejnosc restartu zachowuje dostepnosc bazy dla aplikacji.
        Write-Host "Restarting database..."
        az vm restart --resource-group $ResourceGroup --name $DatabaseVmName

        Write-Host "Restarting application servers..."
        foreach ($VmName in $AppVmNames) {
            az vm restart --resource-group $ResourceGroup --name $VmName
        }
    }

    "status" {
        Write-Host "VM status:"
        az vm list --show-details --resource-group $ResourceGroup --output table

        Write-Host ""
        Write-Host "VPN status:"
        az network vnet-gateway list --resource-group $ResourceGroup --output table
    }

    "plan" {
        # Plan tylko pokazuje zmiany i niczego nie wdraza.
        terraform plan
    }

    "private-plan" {
        # Pokazuje migracje do jednego prywatnego LB bez wykonywania zmian.
        Write-Host "Private-only plan - Helpdesk would require VPN. No apply is executed."
        terraform plan -var="private_only=true"
    }

    "cost-plan" {
        # Finalny wariant nie zawiera Bastiona, a wymagany VPN pozostaje wlaczony.
        Write-Host "Cost plan only - Bastion stays disabled and VPN stays enabled. No apply is executed."
        terraform plan -var="enable_bastion=false" -var="enable_vpn=true"
    }
}
