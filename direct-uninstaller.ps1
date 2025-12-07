<#
.SYNOPSIS
    Uninstaller for pwsh-neofetch
.DESCRIPTION
    Removes pwsh-neofetch from your system, including:
    - Module files (both 'pwsh-neofetch' and legacy 'Neofetch' installations)
    - Configuration files
    - Cache files
.NOTES
    Author: Sriram PR
    Version: 2.0
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

function Remove-ModuleFiles {
    <#
    .SYNOPSIS
        Removes module files for both current and legacy module names
    #>
    
    $moduleNames = @('pwsh-neofetch', 'Neofetch')
    $basePaths = @(
        (Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules'),
        (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules')
    )
    
    $removedCount = 0
    
    foreach ($basePath in $basePaths) {
        foreach ($moduleName in $moduleNames) {
            $modulePath = Join-Path $basePath $moduleName
            
            if (Test-Path $modulePath) {
                try {
                    # Unload module if loaded
                    if (Get-Module -Name $moduleName -ErrorAction SilentlyContinue) {
                        Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
                    }
                    
                    Remove-Item -Path $modulePath -Recurse -Force
                    Write-ColorMessage "Removed module: $modulePath" -ForegroundColor Green
                    $removedCount++
                }
                catch {
                    Write-ColorMessage "Error removing module at ${modulePath}: $_" -ForegroundColor Red
                }
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
                    Write-ColorMessage "Cleaned profile: $profilePath" -ForegroundColor Green
                    $cleanedCount++
                }
            }
            catch {
                Write-ColorMessage "Error cleaning profile at ${profilePath}: $_" -ForegroundColor Red
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
        Write-ColorMessage "Configuration files backed up to: $backupDir" -ForegroundColor Green
    }
    
    foreach ($file in $configFiles) {
        $filePath = Join-Path $env:USERPROFILE $file
        if (Test-Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force
                Write-ColorMessage "Removed config: $filePath" -ForegroundColor Green
                $removedCount++
            }
            catch {
                Write-ColorMessage "Error removing config ${filePath}: $_" -ForegroundColor Red
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
                Write-ColorMessage "Removed cache: $filePath" -ForegroundColor Green
                $removedCount++
            }
            catch {
                Write-ColorMessage "Error removing cache ${filePath}: $_" -ForegroundColor Red
            }
        }
    }
    
    return $removedCount
}

function Uninstall-PwshNeofetch {
    Write-ColorMessage "`n===== pwsh-neofetch Uninstaller =====" -ForegroundColor Cyan
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to uninstall pwsh-neofetch? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-ColorMessage "Uninstallation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-ColorMessage "`nRemoving pwsh-neofetch components...`n" -ForegroundColor Cyan
    
    # Remove module files
    $modulesRemoved = Remove-ModuleFiles
    
    # Remove profile entries
    $profilesCleaned = Remove-ProfileEntries
    
    # Handle config files
    if ($KeepConfig) {
        Write-ColorMessage "Keeping configuration files (--KeepConfig specified)" -ForegroundColor Yellow
        $configsRemoved = 0
    } else {
        $configsRemoved = Remove-ConfigFiles
    }
    
    # Remove cache files
    $cacheRemoved = Remove-CacheFiles
    
    # Summary
    Write-ColorMessage "`n===== Uninstallation Summary =====" -ForegroundColor Cyan
    
    $totalRemoved = $modulesRemoved + $profilesCleaned + $configsRemoved + $cacheRemoved
    
    if ($totalRemoved -gt 0) {
        Write-ColorMessage "pwsh-neofetch has been successfully uninstalled!" -ForegroundColor Green
    } else {
        Write-ColorMessage "No pwsh-neofetch components were found to uninstall." -ForegroundColor Yellow
    }
    
    Write-ColorMessage "`nComponents removed:" -ForegroundColor Cyan
    Write-ColorMessage "  Module files:     $modulesRemoved" -ForegroundColor White
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