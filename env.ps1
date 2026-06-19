param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "restart", "status", "plan")]
    [string]$Action,

    [string]$ResourceGroup = "rg-helpdesk-prod"
)

Set-StrictMode -Version Latest

# Skrypt działa zawsze względem katalogu projektu.
Set-Location $PSScriptRoot

# Tylko te maszyny tworzą warstwę aplikacyjną.
$VmNames = @("helpdesk01", "helpdesk02")

switch ($Action)
{
    "start" {
        # Uruchamiamy VM bez zmieniania pozostałej infrastruktury.
        Write-Host "Starting compute layer..."
        foreach ($VmName in $VmNames) {
            az vm start --resource-group $ResourceGroup --name $VmName
        }
    }

    "stop" {
        # Deallocate zatrzymuje naliczanie kosztu mocy obliczeniowej.
        Write-Host "Stopping compute layer only..."
        foreach ($VmName in $VmNames) {
            az vm deallocate --resource-group $ResourceGroup --name $VmName
        }

        Write-Host "Compute stopped. Network + VPN preserved."
    }

    "restart" {
        # Restart przydaje się po zmianach systemowych na VM.
        Write-Host "Restarting compute layer..."
        foreach ($VmName in $VmNames) {
            az vm restart --resource-group $ResourceGroup --name $VmName
        }
    }

    "status" {
        # Pokazujemy osobno VM i bramę VPN.
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