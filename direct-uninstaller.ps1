#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Uninstaller for pwsh-neofetch
.DESCRIPTION
    Removes pwsh-neofetch from your system, including:
    - Module files from PSModulePath locations
    - Module files from installer fallback locations
    - Legacy 'Neofetch' installations
    - Configuration files
    - Cache files
.NOTES
    Author: Sriram PR
    Version: 2.1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$KeepConfig = $false
)

$ErrorActionPreference = 'Stop'

function Write-ColorMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('White', 'Cyan', 'Green', 'Yellow', 'Red', 'Gray')]
        [string]$ForegroundColor = 'White'
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Get-AllModulePaths {
    <#
    .SYNOPSIS
        Returns all paths where pwsh-neofetch might be installed.
    .DESCRIPTION
        Combines paths from PSModulePath (where PowerShell looks) and
        fallback paths (where installer might have placed the module).
    #>
    
    $moduleNames = @('pwsh-neofetch', 'Neofetch')
    $allPaths = @()
    
    # 1. Get paths from PSModulePath (where PowerShell actually looks)
    $psModulePaths = $env:PSModulePath -split ';' | Where-Object {
        $_ -match '(PowerShell|WindowsPowerShell)\\Modules$'
    }
    
    foreach ($basePath in $psModulePaths) {
        foreach ($moduleName in $moduleNames) {
            $allPaths += Join-Path $basePath $moduleName
        }
    }
    
    # 2. Add hardcoded fallback paths (where installer puts modules)
    $fallbackBases = @(
        (Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules'),
        (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules')
    )
    
    # 3. Add OneDrive fallback paths if OneDrive exists
    if ($env:OneDrive) {
        $fallbackBases += @(
            (Join-Path $env:OneDrive 'Documents\PowerShell\Modules'),
            (Join-Path $env:OneDrive 'Documents\WindowsPowerShell\Modules')
        )
    }
    
    foreach ($basePath in $fallbackBases) {
        foreach ($moduleName in $moduleNames) {
            $allPaths += Join-Path $basePath $moduleName
        }
    }
    
    # Return unique paths only
    return $allPaths | Select-Object -Unique
}

function Remove-ModuleFiles {
    <#
    .SYNOPSIS
        Removes module files from all known locations.
    #>
    
    $allPaths = Get-AllModulePaths
    $removedCount = 0
    
    # Unload modules if currently loaded
    @('pwsh-neofetch', 'Neofetch') | ForEach-Object {
        if (Get-Module -Name $_ -ErrorAction SilentlyContinue) {
            Remove-Module -Name $_ -Force -ErrorAction SilentlyContinue
        }
    }
    
    foreach ($modulePath in $allPaths) {
        if (Test-Path $modulePath) {
            try {
                Remove-Item -Path $modulePath -Recurse -Force
                Write-ColorMessage "  Removed: $modulePath" -ForegroundColor Green
                $removedCount++
            }
            catch {
                Write-ColorMessage "  Error removing ${modulePath}: $_" -ForegroundColor Red
            }
        }
    }
    
    return $removedCount
}

function Remove-ProfileEntries {
    <#
    .SYNOPSIS
        Removes neofetch-related entries from PowerShell profiles
    #>
    
    $profilePaths = @($PROFILE, $PROFILE.CurrentUserAllHosts) | 
        Where-Object { $_ } | 
        Select-Object -Unique
    
    $cleanedCount = 0
    
    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            try {
                $content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
                $originalContent = $content
                
                # Remove pwsh-neofetch related blocks
                $patterns = @(
                    '(?ms)# PowerShell Neofetch.*?Import-Module\s+(pwsh-neofetch|Neofetch).*?}\s*\r?\n?',
                    '(?m)^.*Import-Module\s+(pwsh-neofetch|Neofetch).*$\r?\n?'
                )
                
                foreach ($pattern in $patterns) {
                    $content = $content -replace $pattern, ''
                }
                
                if ($content -ne $originalContent) {
                    Set-Content -Path $profilePath -Value $content.Trim()
                    Write-ColorMessage "  Cleaned profile: $profilePath" -ForegroundColor Green
                    $cleanedCount++
                }
            }
            catch {
                Write-ColorMessage "  Error cleaning profile ${profilePath}: $_" -ForegroundColor Red
            }
        }
    }
    
    return $cleanedCount
}

function Remove-ConfigFiles {
    param(
        [switch]$Backup
    )
    
    $configFiles = @(
        '.neofetch_ascii',
        '.neofetch_cache_expiration',
        '.neofetch_threads',
        '.neofetch_profile_name'
    )
    
    $removedCount = 0
    
    if ($Backup) {
        $backupDir = Join-Path $env:TEMP 'neofetch_config_backup'
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        foreach ($file in $configFiles) {
            $filePath = Join-Path $env:USERPROFILE $file
            if (Test-Path $filePath) {
                Copy-Item -Path $filePath -Destination $backupDir -Force
            }
        }
        Write-ColorMessage "  Config files backed up to: $backupDir" -ForegroundColor Green
    }
    
    foreach ($file in $configFiles) {
        $filePath = Join-Path $env:USERPROFILE $file
        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force
                Write-ColorMessage "  Removed config: $file" -ForegroundColor Green
                $removedCount++
            }
            catch {
                Write-ColorMessage "  Error removing config ${filePath}: $_" -ForegroundColor Red
            }
        }
    }
    
    return $removedCount
}

function Remove-CacheFiles {
    $cacheFiles = @(
        (Join-Path $env:TEMP 'neofetch_cache.xml'),
        (Join-Path $env:TEMP 'neofetch_disk_test.dat')
    )
    
    $removedCount = 0
    
    foreach ($filePath in $cacheFiles) {
        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force
                Write-ColorMessage "  Removed cache: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
                $removedCount++
            }
            catch {
                Write-ColorMessage "  Error removing cache ${filePath}: $_" -ForegroundColor Red
            }
        }
    }
    
    return $removedCount
}

function Show-ModuleLocations {
    <#
    .SYNOPSIS
        Shows where modules will be removed from.
    #>
    
    $allPaths = Get-AllModulePaths
    $foundPaths = $allPaths | Where-Object { Test-Path $_ }
    
    if ($foundPaths.Count -gt 0) {
        Write-ColorMessage "`nModule installations found:" -ForegroundColor Cyan
        foreach ($path in $foundPaths) {
            Write-ColorMessage "  - $path" -ForegroundColor White
        }
    } else {
        Write-ColorMessage "`nNo module installations found." -ForegroundColor Yellow
    }
    
    return $foundPaths.Count
}

function Uninstall-PwshNeofetch {
    Write-ColorMessage "`n===== pwsh-neofetch Uninstaller =====" -ForegroundColor Cyan
    
    # Show what will be removed
    $foundCount = Show-ModuleLocations
    
    if (-not $Force) {
        $confirm = Read-Host "`nAre you sure you want to uninstall pwsh-neofetch? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-ColorMessage "Uninstallation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-ColorMessage "`nRemoving pwsh-neofetch components...`n" -ForegroundColor Cyan
    
    # Remove module files
    Write-ColorMessage "Module files:" -ForegroundColor Cyan
    $modulesRemoved = Remove-ModuleFiles
    if ($modulesRemoved -eq 0) {
        Write-ColorMessage "  No module files found." -ForegroundColor Gray
    }
    
    # Remove profile entries
    Write-ColorMessage "`nProfile entries:" -ForegroundColor Cyan
    $profilesCleaned = Remove-ProfileEntries
    if ($profilesCleaned -eq 0) {
        Write-ColorMessage "  No profile entries found." -ForegroundColor Gray
    }
    
    # Handle config files
    Write-ColorMessage "`nConfiguration files:" -ForegroundColor Cyan
    if ($KeepConfig) {
        Write-ColorMessage "  Keeping configuration files (-KeepConfig specified)" -ForegroundColor Yellow
        $configsRemoved = 0
    } else {
        $configsRemoved = Remove-ConfigFiles
        if ($configsRemoved -eq 0) {
            Write-ColorMessage "  No configuration files found." -ForegroundColor Gray
        }
    }
    
    # Remove cache files
    Write-ColorMessage "`nCache files:" -ForegroundColor Cyan
    $cacheRemoved = Remove-CacheFiles
    if ($cacheRemoved -eq 0) {
        Write-ColorMessage "  No cache files found." -ForegroundColor Gray
    }
    
    # Summary
    Write-ColorMessage "`n===== Uninstallation Summary =====" -ForegroundColor Cyan
    
    $totalRemoved = $modulesRemoved + $profilesCleaned + $configsRemoved + $cacheRemoved
    
    if ($totalRemoved -gt 0) {
        Write-ColorMessage "pwsh-neofetch has been successfully uninstalled!" -ForegroundColor Green
    } else {
        Write-ColorMessage "No pwsh-neofetch components were found to uninstall." -ForegroundColor Yellow
    }
    
    Write-ColorMessage "`nComponents removed:" -ForegroundColor Cyan
    Write-ColorMessage "  Module locations: $modulesRemoved" -ForegroundColor White
    Write-ColorMessage "  Profile entries:  $profilesCleaned" -ForegroundColor White
    Write-ColorMessage "  Config files:     $(if ($KeepConfig) { 'Kept' } else { $configsRemoved })" -ForegroundColor White
    Write-ColorMessage "  Cache files:      $cacheRemoved" -ForegroundColor White
    
    Write-ColorMessage "`nThank you for trying pwsh-neofetch!" -ForegroundColor Cyan
}

# Main execution
try {
    Uninstall-PwshNeofetch
}
catch {
    Write-ColorMessage "`nCritical error during uninstallation: $_" -ForegroundColor Red
    Write-ColorMessage "Uninstallation may be incomplete." -ForegroundColor Red
    exit 1
}