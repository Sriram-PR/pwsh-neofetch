#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$failed = @()

Write-Host "=== pwsh-neofetch Smoke Test ===" -ForegroundColor Cyan

# Reload module
Remove-Module pwsh-neofetch -Force -ErrorAction SilentlyContinue
Import-Module ./ps-gallery-build/pwsh-neofetch/pwsh-neofetch.psd1 -Force

# Test 1: Module loads
Write-Host "`n[1] Module load..." -NoNewline
try {
    $mod = Get-Module pwsh-neofetch
    if ($mod) { Write-Host " PASS" -ForegroundColor Green }
    else { throw "Module not loaded" }
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "Module load" }

# Test 2: Alias exists
Write-Host "[2] Alias exists..." -NoNewline
try {
    $alias = Get-Alias neofetch -ErrorAction Stop
    if ($alias.Definition -eq 'Invoke-Neofetch') { Write-Host " PASS" -ForegroundColor Green }
    else { throw "Alias points to wrong command" }
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "Alias" }

# Test 3: Help doesn't throw
Write-Host "[3] -help parameter..." -NoNewline
try {
    $null = neofetch -help
    Write-Host " PASS" -ForegroundColor Green
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "-help" }

# Test 4: -AsObject returns object
Write-Host "[4] -AsObject output..." -NoNewline
try {
    $obj = neofetch -AsObject -nocache
    if ($obj.PSTypeNames -contains 'Neofetch.SystemInfo' -and $obj.OS -and $obj.CollectedAt) {
        Write-Host " PASS" -ForegroundColor Green
    } else { throw "Invalid object structure" }
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "-AsObject" }

# Test 5: -AsObject converts to JSON
Write-Host "[5] -AsObject JSON conversion..." -NoNewline
try {
    $json = neofetch -AsObject -nocache | ConvertTo-Json
    if ($json -match '"OS"') { Write-Host " PASS" -ForegroundColor Green }
    else { throw "JSON missing expected properties" }
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "JSON conversion" }

# Test 6: WhatIf parameter exists
Write-Host "[6] -WhatIf parameter exists..." -NoNewline
try {
    $cmd = Get-Command Invoke-Neofetch
    if ($cmd.Parameters.ContainsKey('WhatIf')) { Write-Host " PASS" -ForegroundColor Green }
    else { throw "WhatIf parameter missing" }
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "-WhatIf" }

# Test 7: Basic neofetch runs without error
Write-Host "[7] Basic execution..." -NoNewline
try {
    $null = neofetch -nocache 2>&1
    Write-Host " PASS" -ForegroundColor Green
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "Basic execution" }

# Test 8: -minimal works
Write-Host "[8] -minimal parameter..." -NoNewline
try {
    $null = neofetch -minimal -nocache 2>&1
    Write-Host " PASS" -ForegroundColor Green
} catch { Write-Host " FAIL: $_" -ForegroundColor Red; $failed += "-minimal" }

# Summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
if ($failed.Count -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Failed tests: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}