param(
    [string]$ResourceGroup = "rg-helpdesk-prod",
    [string]$OutputDirectory = "docs/evidence"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputPath = Join-Path $ProjectRoot $OutputDirectory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

function Export-AzJson {
    param(
        [string[]]$Arguments,
        [string]$FileName
    )

    $Content = & az @Arguments --output json
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed for $FileName."
    }

    $Target = Join-Path $OutputPath $FileName
    [IO.File]::WriteAllText(
        $Target,
        ($Content -join [Environment]::NewLine),
        [Text.UTF8Encoding]::new($false)
    )
    Write-Host "Saved: $FileName"
}

$Account = az account show --output json | ConvertFrom-Json
if (-not $Account.id) {
    throw "Azure CLI session is not available. Run az login first."
}

Export-AzJson `
    -Arguments @("resource", "list", "--resource-group", $ResourceGroup) `
    -FileName "azure-resources.json"

Export-AzJson `
    -Arguments @("vm", "list", "--resource-group", $ResourceGroup, "--show-details") `
    -FileName "vm-status.json"

$Nics = @("nic-helpdesk01", "nic-helpdesk02", "nic-helpdesk-db01")
$NsgQuery = "value[].effectiveSecurityRules[].{name:name,priority:priority,direction:direction,access:access,protocol:protocol,source:sourceAddressPrefix,sourcePorts:sourcePortRanges,destination:destinationAddressPrefix,destinationPorts:destinationPortRanges}"
foreach ($Nic in $Nics) {
    Export-AzJson `
        -Arguments @("network", "nic", "show-effective-route-table", "--resource-group", $ResourceGroup, "--name", $Nic) `
        -FileName "$Nic-routes.json"

    Export-AzJson `
        -Arguments @("network", "nic", "list-effective-nsg", "--resource-group", $ResourceGroup, "--name", $Nic, "--query", $NsgQuery) `
        -FileName "$Nic-nsg.json"
}

$TerraformOutput = & terraform @("-chdir=$ProjectRoot", "output", "-json")
if ($LASTEXITCODE -ne 0) {
    throw "Terraform output command failed."
}
[IO.File]::WriteAllText(
    (Join-Path $OutputPath "terraform-outputs.json"),
    ($TerraformOutput -join [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
)
Write-Host "Saved: terraform-outputs.json"

$Manifest = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    subscription     = $Account.name
    subscription_id  = $Account.id
    resource_group   = $ResourceGroup
    files            = @(Get-ChildItem -LiteralPath $OutputPath -File | Select-Object -ExpandProperty Name | Sort-Object)
}

[IO.File]::WriteAllText(
    (Join-Path $OutputPath "manifest.json"),
    ($Manifest | ConvertTo-Json -Depth 5),
    [Text.UTF8Encoding]::new($false)
)
Write-Host "Evidence export completed: $OutputPath"