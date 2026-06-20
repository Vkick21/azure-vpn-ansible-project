param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("List", "Add", "Remove")]
    [string]$Action,

    [string]$UserPrincipalName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Dostep do panelu wynika wylacznie z czlonkostwa w tej grupie.
$GroupId = "<ENTRA_OPERATOR_GROUP_ID>"

if ($Action -eq "List") {
    az ad group member list --group $GroupId --query "[].{Name:displayName,Login:userPrincipalName}" --output table
    exit $LASTEXITCODE
}

if (-not $UserPrincipalName) {
    throw "Dla akcji $Action podaj -UserPrincipalName."
}

$UserId = az ad user show --id $UserPrincipalName --query id --output tsv
if (-not $UserId) {
    throw "Nie znaleziono uzytkownika $UserPrincipalName."
}

if ($Action -eq "Add") {
    az ad group member add --group $GroupId --member-id $UserId
    Write-Host "Dodano operatora $UserPrincipalName."
}
else {
    az ad group member remove --group $GroupId --member-id $UserId
    Write-Host "Usunieto operatora $UserPrincipalName."
}
