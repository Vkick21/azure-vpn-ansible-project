param(
    [string]$Action
)

Set-Location "C:\Projects\terraform"

switch ($Action)
{
    "start" {
        Write-Host "Starting infrastructure (Terraform apply)..."
        terraform apply -auto-approve
    }

    "stop" {
        Write-Host "Stopping compute layer only..."

        # ONLY COMPUTE — safe cost reduction
        az vm deallocate -g rg-helpdesk-prod -n helpdesk01
        az vm deallocate -g rg-helpdesk-prod -n helpdesk02
        az vm deallocate -g rg-helpdesk-prod -n ansible-mgmt

        Write-Host "Compute stopped. Network + VPN preserved."
    }

    "restart" {
        Write-Host "Restart cycle..."
        az vm start -g rg-helpdesk-prod -n helpdesk01
        az vm start -g rg-helpdesk-prod -n helpdesk02
        az vm start -g rg-helpdesk-prod -n ansible-mgmt
    }

    "status" {
        Write-Host "VM status:"
        az vm list -d -g rg-helpdesk-prod -o table

        Write-Host "`nVPN status:"
        az network vnet-gateway list -g rg-helpdesk-prod -o table
    }

    "plan" {
        terraform plan
    }

    "full-reset" {
        Write-Host "DANGER: full terraform destroy + apply"
        terraform destroy -auto-approve
        terraform apply -auto-approve
    }
}