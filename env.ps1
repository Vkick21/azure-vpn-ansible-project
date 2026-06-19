param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "restart", "status", "plan")]
    [string]$Action,

    [string]$ResourceGroup = "rg-helpdesk-prod"
)

Set-StrictMode -Version Latest

# Skrypt działa zawsze względem katalogu projektu.
Set-Location $PSScriptRoot

# Baza uruchamia się przed aplikacją i zatrzymuje jako ostatnia.
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
        # Najpierw zatrzymujemy aplikację, żeby nie zerwała połączeń do bazy.
        Write-Host "Stopping application servers..."
        foreach ($VmName in $AppVmNames) {
            az vm deallocate --resource-group $ResourceGroup --name $VmName
        }

        Write-Host "Stopping database..."
        az vm deallocate --resource-group $ResourceGroup --name $DatabaseVmName
        Write-Host "Compute stopped. Network + VPN preserved."
    }

    "restart" {
        # Kolejność restartu zachowuje dostępność bazy dla aplikacji.
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
        # Plan tylko pokazuje zmiany i niczego nie wdraża.
        terraform plan
    }
}