# Monitor pilnuje godzin pracy i ogranicza koszt uruchomionych VM.
$base = Split-Path -Parent $MyInvocation.MyCommand.Path

# =========================
# OVERRIDE (GLOBAL KILL SWITCH)
# =========================
if (Test-Path "$base\override.flag") {
    Write-Host "OVERRIDE ACTIVE - system paused"
    exit
}

# =========================
# AZURE AUTH CONTEXT
# =========================
if (-not $env:ARM_SUBSCRIPTION_ID) {
    $env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
}

# =========================
# SESSION MEMORY (ANTI-FLAP)
# =========================
$stoppedVMs = @{}

while ($true)
{
    # =========================
    # TIME WINDOW CONTROL
    # =========================
    $hour = (Get-Date).Hour
    $workingHours = ($hour -ge 7 -and $hour -lt 22)

    Write-Host "Current hour: $hour | Working hours: $workingHours"

    # =========================
    # FETCH VMS
    # =========================
    $vms = az vm list -d -g rg-helpdesk-prod -o json | ConvertFrom-Json

    foreach ($vm in $vms)
    {
        $name = $vm.name
        $power = $vm.powerState

        Write-Host "VM: $name -> $power"

        # =========================
        # METRICS COLLECTION
        # =========================
        $resource = "/subscriptions/$env:ARM_SUBSCRIPTION_ID/resourceGroups/rg-helpdesk-prod/providers/Microsoft.Compute/virtualMachines/$name"

        $cpuRaw = az monitor metrics list `
            --resource $resource `
            --metric "Percentage CPU" `
            --interval PT5M `
            --aggregation Average `
            --query "value[0].timeseries[0].data[-1].average" `
            -o tsv

        $netRaw = az monitor metrics list `
            --resource $resource `
            --metric "Network In Total" `
            --interval PT5M `
            --aggregation Total `
            --query "value[0].timeseries[0].data[-1].total" `
            -o tsv

        if ([string]::IsNullOrWhiteSpace($cpuRaw)) { $cpuRaw = 0 }
        if ([string]::IsNullOrWhiteSpace($netRaw)) { $netRaw = 0 }

        [double]$cpu = $cpuRaw
        [double]$net = $netRaw

        Write-Host "CPU=$cpu NET=$net"

        # =========================
        # AUTO START LOGIC
        # =========================
        if ($power -like "*deallocated")
        {
            if ($cpu -gt 5 -or $net -gt 1000)
            {
                Write-Host "Activity detected -> STARTING $name"
                az vm start -g rg-helpdesk-prod -n $name
            }

            continue
        }

        # =========================
        # AUTO STOP LOGIC (TIME-AWARE)
        # =========================
        if ($power -like "*running")
        {
            # anti-flap session guard
            if ($stoppedVMs.ContainsKey($name)) {
                continue
            }

            if (-not $workingHours)
            {
                # NIGHT MODE (FULL AUTO COST CONTROL)
                if ($cpu -lt 2 -and $net -lt 500)
                {
                    Write-Host "OFF HOURS idle -> STOPPING $name"
                    az vm deallocate -g rg-helpdesk-prod -n $name
                    $stoppedVMs[$name] = $true
                }
            }
            else
            {
                # DAY MODE (SAFE)
                Write-Host "Working hours active -> no auto-stop allowed"
            }
        }
    }

    # =========================
    # LOOP DELAY (ANTI THROTTLE)
    # =========================
    Start-Sleep -Seconds (180 + (Get-Random -Minimum 0 -Maximum 30))
}