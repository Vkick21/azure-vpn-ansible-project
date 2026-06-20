param(
    [string]$ResourceGroup = "rg-helpdesk-prod",
    [string]$OutputDirectory = "docs/costs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# The report uses the current Azure CLI session and never saves its access token.
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputPath = Join-Path $ProjectRoot $OutputDirectory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

$Account = az account show --output json | ConvertFrom-Json
if (-not $Account.id) {
    throw "Azure CLI session is not available. Run az login first."
}

$Token = (az account get-access-token `
    --resource https://management.azure.com `
    --query accessToken `
    --output tsv).Trim()

$Uri = "https://management.azure.com/subscriptions/$($Account.id)/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
$Headers = @{ Authorization = "Bearer $Token" }

function Invoke-ProjectCostQuery {
    param([hashtable]$Dataset)

    $Body = @{
        type      = "ActualCost"
        timeframe = "MonthToDate"
        dataset   = $Dataset
    } | ConvertTo-Json -Depth 12

    Invoke-RestMethod `
        -Method Post `
        -Uri $Uri `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body $Body
}

function Convert-CostRows {
    param($Properties)

    $Names = @($Properties.columns | ForEach-Object { $_.name })
    foreach ($Row in $Properties.rows) {
        $Record = [ordered]@{}
        for ($Index = 0; $Index -lt $Names.Count; $Index++) {
            $Record[$Names[$Index]] = $Row[$Index]
        }
        [pscustomobject]$Record
    }
}

$Filter = @{
    dimensions = @{
        name     = "ResourceGroupName"
        operator = "In"
        values   = @($ResourceGroup)
    }
}

$DailyResult = Invoke-ProjectCostQuery -Dataset @{
    granularity = "Daily"
    aggregation = @{
        totalCost = @{
            name     = "PreTaxCost"
            function = "Sum"
        }
    }
    filter = $Filter
}

$ServiceResult = Invoke-ProjectCostQuery -Dataset @{
    granularity = "None"
    aggregation = @{
        totalCost = @{
            name     = "PreTaxCost"
            function = "Sum"
        }
    }
    grouping = @(
        @{
            type = "Dimension"
            name = "ServiceName"
        }
    )
    filter = $Filter
}

$DailyRows = @(Convert-CostRows $DailyResult.properties)
$ServiceRows = @(Convert-CostRows $ServiceResult.properties)

$DailyRows |
    Sort-Object UsageDate |
    Export-Csv -LiteralPath (Join-Path $OutputPath "azure-cost-daily.csv") -NoTypeInformation -Encoding UTF8

$ServiceRows |
    Sort-Object PreTaxCost -Descending |
    Export-Csv -LiteralPath (Join-Path $OutputPath "azure-cost-by-service.csv") -NoTypeInformation -Encoding UTF8

$Resources = az resource list --resource-group $ResourceGroup --output json | ConvertFrom-Json
$Resources |
    Select-Object name, type, location, resourceGroup |
    Sort-Object type, name |
    Export-Csv -LiteralPath (Join-Path $OutputPath "azure-resources.csv") -NoTypeInformation -Encoding UTF8

$Total = ($ServiceRows | Measure-Object -Property PreTaxCost -Sum).Sum
$Currency = ($ServiceRows | Select-Object -First 1).Currency
$GeneratedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")

Write-Host "Azure cost report generated."
Write-Host "Resource group: $ResourceGroup"
Write-Host ("Month-to-date cost: {0:N2} {1}" -f $Total, $Currency)
Write-Host "Output: $OutputPath"