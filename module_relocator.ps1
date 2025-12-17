#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Relocates pwsh-neofetch module to the correct PowerShell Modules folder.
.DESCRIPTION
    The direct-installer uses standard paths (e.g., Documents\WindowsPowerShell\Modules),
    but PowerShell may expect modules elsewhere due to:
    - OneDrive Known Folder Move (KFM)
    - Localized folder names (e.g., Japanese ドキュメント, German Dokumente)
    - Custom PSModulePath configuration
    
    This script finds pwsh-neofetch wherever it was installed and copies it to
    the correct location detected from $env:PSModulePath.
.NOTES
    Author: Sriram PR
    Version: 2.1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$script:ModuleName = 'pwsh-neofetch'

function Get-TargetModulePath {
    <#
    .SYNOPSIS
        Determines where PowerShell actually expects user modules by reading $env:PSModulePath.
    #>
    
    $isPSCore = $PSVersionTable.PSEdition -eq 'Core'
    $searchPattern = if ($isPSCore) { 'PowerShell\\Modules$' } else { 'WindowsPowerShell\\Modules$' }
    
    # Find user-specific path from PSModulePath
    $userModulePath = $env:PSModulePath -split ';' | Where-Object {
        $_ -match $searchPattern -and 
        $_ -notmatch '^C:\\Program Files' -and 
        $_ -notmatch '^C:\\WINDOWS'
    } | Select-Object -First 1
    
    if ($userModulePath) {
        return $userModulePath
    }
    
    return $null
}

function Find-ModuleInFallbackPaths {
    <#
    .SYNOPSIS
        Searches common installation paths where direct-installer may have placed the module.
    #>
    
    $fallbackPaths = @(
        # Standard paths (where installer puts it)
        (Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$script:ModuleName"),
        (Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$script:ModuleName")
    )
    
    # Add OneDrive variants if OneDrive exists
    if ($env:OneDrive) {
        $fallbackPaths += @(
            (Join-Path $env:OneDrive "Documents\WindowsPowerShell\Modules\$script:ModuleName"),
            (Join-Path $env:OneDrive "Documents\PowerShell\Modules\$script:ModuleName")
        )
    }
    
    foreach ($path in $fallbackPaths) {
        if (Test-Path $path) {
            $psd1 = Join-Path $path "pwsh-neofetch.psd1"
            $psm1 = Join-Path $path "pwsh-neofetch.psm1"
            
            if ((Test-Path $psd1) -and (Test-Path $psm1)) {
                return $path
            }
        }
    }
    
    return $null
}

function Find-ModuleInOneDrive {
    <#
    .SYNOPSIS
        Searches OneDrive folders recursively for the module (handles localized folder names).
    #>
    
    # Get OneDrive paths from registry
    $oneDrivePaths = @()
    
    $oneDriveKeys = @(
        "HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
        "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1",
        "HKCU:\Software\Microsoft\OneDrive\Accounts\Business2"
    )
    
    foreach ($keyPath in $oneDriveKeys) {
        if (Test-Path $keyPath) {
            try {
                $userFolder = Get-ItemProperty -Path $keyPath -Name "UserFolder" -ErrorAction SilentlyContinue
                if ($userFolder -and $userFolder.UserFolder -and (Test-Path $userFolder.UserFolder)) {
                    $oneDrivePaths += $userFolder.UserFolder
                }
            }
            catch {
                Write-Verbose "Could not read registry key: $keyPath"
            }
        }
    }
    
    # Fallback: scan user profile for OneDrive folders
    if ($oneDrivePaths.Count -eq 0) {
        $potentialOneDrives = Get-ChildItem -Path $env:USERPROFILE -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "OneDrive*" }
        
        foreach ($od in $potentialOneDrives) {
            $oneDrivePaths += $od.FullName
        }
    }
    
    $oneDrivePaths = $oneDrivePaths | Select-Object -Unique
    
    if ($oneDrivePaths.Count -eq 0) {
        return $null
    }
    
    foreach ($oneDrivePath in $oneDrivePaths) {
        Write-Host "  Searching: $oneDrivePath" -ForegroundColor Gray
        
        try {
            $modulePaths = Get-ChildItem -Path $oneDrivePath -Recurse -Directory -ErrorAction SilentlyContinue -Depth 4 |
                Where-Object { $_.Name -eq $script:ModuleName } |
                Where-Object { 
                    $_.Parent.Name -eq "Modules" -and 
                    ($_.Parent.Parent.Name -eq "PowerShell" -or $_.Parent.Parent.Name -eq "WindowsPowerShell")
                }
            
            foreach ($modulePath in $modulePaths) {
                $psd1 = Join-Path $modulePath.FullName "pwsh-neofetch.psd1"
                $psm1 = Join-Path $modulePath.FullName "pwsh-neofetch.psm1"
                
                if ((Test-Path $psd1) -and (Test-Path $psm1)) {
                    return $modulePath.FullName
                }
            }
        }
        catch {
            Write-Verbose "Error searching $oneDrivePath : $_"
        }
    }
    
    return $null
}

# =============================================================================
# Main Script
# =============================================================================

Write-Host "`n===== pwsh-neofetch Module Relocator =====" -ForegroundColor Cyan
Write-Host "This script moves the module to where PowerShell expects it.`n" -ForegroundColor Cyan

# Step 1: Determine where PowerShell expects modules
Write-Host "[1/3] Detecting correct module path from PSModulePath..." -ForegroundColor Cyan

$targetBase = Get-TargetModulePath

if (-not $targetBase) {
    Write-Host "Error: Could not detect user module path from PSModulePath." -ForegroundColor Red
    Write-Host "Your PSModulePath:" -ForegroundColor Yellow
    $env:PSModulePath -split ';' | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    Write-Host "`nPlease ensure PSModulePath includes a user-writable Modules folder." -ForegroundColor Yellow
    exit 1
}

$targetModuleFolder = Join-Path $targetBase $script:ModuleName
Write-Host "  Target: $targetBase" -ForegroundColor Green

# Step 2: Check if module already exists at target
if (Test-Path $targetModuleFolder) {
    $psd1 = Join-Path $targetModuleFolder "pwsh-neofetch.psd1"
    if (Test-Path $psd1) {
        Write-Host "`nModule already exists at correct location: $targetModuleFolder" -ForegroundColor Green
        
        try {
            $manifest = Test-ModuleManifest -Path $psd1 -ErrorAction Stop -WarningAction SilentlyContinue
            Write-Host "  Version: $($manifest.Version)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Module exists but manifest validation failed: $_"
        }
        
        Write-Host "`nNo relocation needed. Try running 'neofetch' in a new PowerShell window." -ForegroundColor Cyan
        exit 0
    }
}

# Step 3: Find where the module is currently installed
Write-Host "`n[2/3] Searching for installed module..." -ForegroundColor Cyan

# First check standard fallback paths
$sourcePath = Find-ModuleInFallbackPaths

if (-not $sourcePath) {
    Write-Host "  Not found in standard paths, searching OneDrive..." -ForegroundColor Yellow
    $sourcePath = Find-ModuleInOneDrive
}

if (-not $sourcePath) {
    Write-Host "`nError: Could not find pwsh-neofetch module anywhere." -ForegroundColor Red
    Write-Host "`nSearched locations:" -ForegroundColor Yellow
    Write-Host "  - $env:USERPROFILE\Documents\WindowsPowerShell\Modules" -ForegroundColor Gray
    Write-Host "  - $env:USERPROFILE\Documents\PowerShell\Modules" -ForegroundColor Gray
    Write-Host "  - OneDrive folders (recursive)" -ForegroundColor Gray
    Write-Host "`nPlease run the installer first:" -ForegroundColor Cyan
    Write-Host "  .\direct-installer.ps1" -ForegroundColor White
    Write-Host "  or" -ForegroundColor Gray
    Write-Host "  Install-Module -Name pwsh-neofetch" -ForegroundColor White
    exit 1
}

Write-Host "  Found: $sourcePath" -ForegroundColor Green

# Check if source and target are the same
if ($sourcePath -eq $targetModuleFolder) {
    Write-Host "`nModule is already in the correct location!" -ForegroundColor Green
    Write-Host "Try running 'neofetch' in a new PowerShell window." -ForegroundColor Cyan
    exit 0
}

# Step 4: Copy to correct location
Write-Host "`n[3/3] Relocating module..." -ForegroundColor Cyan
Write-Host "  From: $sourcePath" -ForegroundColor Gray
Write-Host "  To:   $targetModuleFolder" -ForegroundColor Gray

# Create target directory if needed
if (-not (Test-Path $targetBase)) {
    Write-Host "  Creating directory: $targetBase" -ForegroundColor Yellow
    New-Item -Path $targetBase -ItemType Directory -Force | Out-Null
}

# Handle existing target
if (Test-Path $targetModuleFolder) {
    $overwrite = Read-Host "Target folder exists. Overwrite? (Y/n)"
    if ($overwrite -match '^[Nn]') {
        Write-Host "Relocation cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    $backupFolder = "$targetModuleFolder.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "  Creating backup: $backupFolder" -ForegroundColor Yellow
    Rename-Item -Path $targetModuleFolder -NewName (Split-Path -Leaf $backupFolder)
}

# Copy module
Copy-Item -Path $sourcePath -Destination $targetModuleFolder -Recurse -Force

# Verify
Write-Host "`n===== Relocation Complete! =====" -ForegroundColor Green

$verifyPsd1 = Join-Path $targetModuleFolder "pwsh-neofetch.psd1"
if (Test-Path $verifyPsd1) {
    try {
        $manifest = Test-ModuleManifest -Path $verifyPsd1 -ErrorAction Stop -WarningAction SilentlyContinue
        Write-Host "  Verified: Version $($manifest.Version) installed at correct location." -ForegroundColor Green
    }
    catch {
        Write-Warning "Module copied but manifest validation failed: $_"
    }
}

Write-Host "`nYou can now use 'neofetch' from any new PowerShell window." -ForegroundColor Cyan
Write-Host "The old installation at '$sourcePath' can be safely deleted." -ForegroundColor Gray