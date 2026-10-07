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

# _*-prefixed dirs (shared overlays like _common-display) must be skipped
$tmpOverlay = Join-Path $root '_sdd_test_overlay'
New-Item -ItemType Directory -Path $tmpOverlay -Force | Out-Null
Set-Content -Path (Join-Path $tmpOverlay 'device.psd1') -Value "@{ Name='should not load' }"
try {
    $again = Get-DeviceProfiles -DevicesRoot $root
    if ($again | Where-Object { $_.Id -eq '_sdd_test_overlay' }) {
        throw "FAIL: _*-prefixed overlay dir was not skipped"
    }
} finally {
    Remove-Item -Path $tmpOverlay -Recurse -Force
}

Write-Host 'PASS: device profile loader' -ForegroundColor Green
