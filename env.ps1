param(
    [string]$Action
)

Set-Location "C:\Projects\terraform"

switch ($Action)
{
    "start" {
        terraform apply -auto-approve -var="env_mode=full"
    }

    "stop" {
        terraform apply -auto-approve -var="env_mode=stop"
    }

    "plan" {
        terraform plan -var="env_mode=full"
    }

    "status" {
        terraform state list
        az vm list -g rg-helpdesk-prod -o table
        az network vnet-gateway list -g rg-helpdesk-prod -o table
    }

    "destroy" {
        terraform destroy -auto-approve
    }
}