$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Load-DeviceProfiles.ps1"

$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'devices'
$profiles = Get-DeviceProfiles -DevicesRoot $root

$ids = ($profiles | ForEach-Object { $_.Id }) | Sort-Object
if (($ids -join ',') -ne 'headless,waveshare-p4-touch-4b') {
    throw "FAIL: unexpected device ids: $($ids -join ',')"
}

$hl = Select-DeviceProfile -Profiles $profiles -DeviceId 'headless'
if ($hl.HasDisplay -ne $false) { throw "FAIL: headless HasDisplay should be false" }

$ws = Select-DeviceProfile -Profiles $profiles -DeviceId 'waveshare-p4-touch-4b'
if ($ws.HasDisplay -ne $true) { throw "FAIL: waveshare HasDisplay should be true" }
if ($ws.Bsp.CmakeName -ne 'esp32_p4_wifi6_touch_lcd_4b') { throw "FAIL: bad CmakeName" }

try {
    Select-DeviceProfile -Profiles $profiles -DeviceId 'nope' | Out-Null
    throw "FAIL: unknown device did not throw"
} catch {
    if ($_.Exception.Message -notlike 'Unknown device*') { throw }
}

Write-Host 'PASS: device profile loader' -ForegroundColor Green
