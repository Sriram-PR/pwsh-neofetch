<#
.SYNOPSIS
    Uninstaller for PowerShell Neofetch
.DESCRIPTION
    This script removes PowerShell Neofetch from your system, including modules, installation files, and profile references.
.NOTES
    Author: Sriram PR
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "$env:USERPROFILE\Tools\pwsh-neofetch",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepConfig = $false
)

function Write-ColorMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Remove-NeofetchModule {
    $modulePaths = @(
        "$env:USERPROFILE\Documents\PowerShell\Modules\Neofetch",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Neofetch"
    )
    
    $modulesRemoved = $false
    
    foreach ($path in $modulePaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-ColorMessage "Removed module at: $path" -ForegroundColor Green
                $modulesRemoved = $true
            }
            catch {
                Write-ColorMessage "Error removing module at $path`: $_" -ForegroundColor Red
            }
        }
    }
    
    return $modulesRemoved
}

function Remove-NeofetchFromProfile {
    $profilePaths = @(
        $PROFILE,
        $PROFILE.CurrentUserAllHosts
    )
    
    $profilesCleaned = $false
    
    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            try {
                $content = Get-Content -Path $profilePath -Raw
                
                $pattern = "(?ms)# PowerShell Neofetch.*?Import-Module Neofetch.*?}\s*\r?\n"
                
                if ($content -match $pattern) {
                    $newContent = $content -replace $pattern, ""
                    Set-Content -Path $profilePath -Value $newContent
                    Write-ColorMessage "Removed Neofetch from profile: $profilePath" -ForegroundColor Green
                    $profilesCleaned = $true
                }
            }
            catch {
                Write-ColorMessage "Error cleaning profile at $profilePath`: $_" -ForegroundColor Red
            }
        }
    }
    
    return $profilesCleaned
}

function Uninstall-Neofetch {
    Write-ColorMessage "`n===== PowerShell Neofetch Uninstaller =====" -ForegroundColor Cyan
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to uninstall PowerShell Neofetch? (y/n)"
        if ($confirm -ne "y") {
            Write-ColorMessage "Uninstallation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    Write-ColorMessage "Beginning uninstallation process..." -ForegroundColor Cyan
    
    $modulesRemoved = Remove-NeofetchModule
    
    $profilesCleaned = Remove-NeofetchFromProfile
    
    $installationRemoved = $false
    if (Test-Path $InstallPath) {
        try {
            if ($KeepConfig) {
                $configFiles = @(
                    ".neofetch_ascii",
                    ".neofetch_cache_expiration",
                    ".neofetch_threads",
                    ".neofetch_profile_name"
                )
                
                $backupDir = Join-Path $env:TEMP "neofetch_config_backup"
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                
                foreach ($file in $configFiles) {
                    $filePath = Join-Path $env:USERPROFILE $file
                    if (Test-Path $filePath) {
                        Copy-Item -Path $filePath -Destination $backupDir
                    }
                }
                
                Write-ColorMessage "Configuration files backed up to: $backupDir" -ForegroundColor Green
            }
            
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-ColorMessage "Removed installation directory: $InstallPath" -ForegroundColor Green
            $installationRemoved = $true
            
            if ($KeepConfig) {
                $backupDir = Join-Path $env:TEMP "neofetch_config_backup"
                if (Test-Path $backupDir) {
                    foreach ($file in Get-ChildItem -Path $backupDir) {
                        Copy-Item -Path $file.FullName -Destination $env:USERPROFILE
                    }
                    Write-ColorMessage "Restored configuration files to user profile." -ForegroundColor Green
                }
            }
        }
        catch {
            Write-ColorMessage "Error removing installation directory: $_" -ForegroundColor Red
        }
    }
    else {
        Write-ColorMessage "Installation directory not found at: $InstallPath" -ForegroundColor Yellow
    }
    
    $cachePath = Join-Path $env:TEMP "neofetch_cache.xml"
    if (Test-Path $cachePath) {
        try {
            Remove-Item -Path $cachePath -Force
            Write-ColorMessage "Removed cache file: $cachePath" -ForegroundColor Green
        }
        catch {
            Write-ColorMessage "Error removing cache file: $_" -ForegroundColor Red
        }
    }
    
    $testFilePath = Join-Path $env:TEMP "neofetch_disk_test.dat"
    if (Test-Path $testFilePath) {
        try {
            Remove-Item -Path $testFilePath -Force
            Write-ColorMessage "Removed test file: $testFilePath" -ForegroundColor Green
        }
        catch {
            Write-ColorMessage "Error removing test file: $_" -ForegroundColor Red
        }
    }
    
    Write-ColorMessage "`n===== Uninstallation Summary =====" -ForegroundColor Cyan
    
    if ($modulesRemoved -or $profilesCleaned -or $installationRemoved) {
        Write-ColorMessage "PowerShell Neofetch has been successfully uninstalled!" -ForegroundColor Green
    }
    else {
        Write-ColorMessage "No PowerShell Neofetch components were found to uninstall." -ForegroundColor Yellow
    }
    
    $moduleStatus = if ($modulesRemoved) { "Yes" } else { "No" }
    $profileStatus = if ($profilesCleaned) { "Yes" } else { "No" }
    $installStatus = if ($installationRemoved) { "Yes" } else { "No" }
    
    Write-ColorMessage "PowerShell Neofetch components removed:" -ForegroundColor Cyan
    Write-ColorMessage "  Module Files: $moduleStatus" -ForegroundColor White
    Write-ColorMessage "  Profile References: $profileStatus" -ForegroundColor White
    Write-ColorMessage "  Installation Directory: $installStatus" -ForegroundColor White
    
    Write-ColorMessage "`nThank you for trying PowerShell Neofetch!" -ForegroundColor Cyan
}

try {
    Uninstall-Neofetch
}
catch {
    Write-ColorMessage "Critical error during uninstallation: $_" -ForegroundColor Red
    Write-ColorMessage "Uninstallation may be incomplete." -ForegroundColor Red
}