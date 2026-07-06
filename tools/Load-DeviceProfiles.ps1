# Dot-source into the build script. Provides device-profile discovery/selection.
Set-StrictMode -Version Latest

function Get-DeviceProfiles {
    param([Parameter(Mandatory)][string]$DevicesRoot)

    if (-not (Test-Path $DevicesRoot)) {
        throw "Devices root not found: $DevicesRoot"
    }

    $profiles = @()
    $dirs = Get-ChildItem -Path $DevicesRoot -Directory |
        Where-Object { $_.Name -notlike '_*' }   # skip shared overlay dirs like _common-display

    foreach ($dir in $dirs) {
        $manifestPath = Join-Path $dir.FullName 'device.psd1'
        if (-not (Test-Path $manifestPath)) { continue }
        $data = Import-PowerShellDataFile -Path $manifestPath
        $data.Id = $dir.Name
        $data._Path = $dir.FullName
        $profiles += $data
    }

    if ($profiles.Count -eq 0) {
        throw "No device profiles found under $DevicesRoot"
    }
    return ,$profiles
}

function Select-DeviceProfile {
    param(
        [Parameter(Mandatory)][array]$Profiles,
        [string]$DeviceId = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        $match = $Profiles | Where-Object { $_.Id -ieq $DeviceId }
        if (-not $match) {
            $ids = ($Profiles | ForEach-Object { $_.Id }) -join ', '
            throw "Unknown device '$DeviceId'. Available: $ids"
        }
        return $match
    }

    Write-Host "`nSelect target device:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Profiles[$i].Name)
    }
    $choice = Read-Host "Enter number (1-$($Profiles.Count))"
    $idx = 0
    if (-not [int]::TryParse($choice, [ref]$idx) -or $idx -lt 1 -or $idx -gt $Profiles.Count) {
        throw "Invalid selection: $choice"
    }
    return $Profiles[$idx - 1]
}
