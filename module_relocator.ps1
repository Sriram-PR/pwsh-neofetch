#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Relocates pwsh-neofetch module from OneDrive to local PowerShell Modules folder.
.DESCRIPTION
    OneDrive's Known Folder Move (KFM) feature can cause PowerShell module path issues.
    This script finds pwsh-neofetch in OneDrive folders (regardless of language/locale)
    and copies it to the standard local Modules path.
    
    S15: Uses recursive search instead of hardcoded localised paths to support all languages.
.NOTES
    Author: Sriram PR
    Version: 2.0
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$targetBase = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
$targetModuleFolder = Join-Path -Path $targetBase -ChildPath "pwsh-neofetch"

if (-not (Test-Path -Path $targetBase)) {
    Write-Host "Creating target directory: $targetBase" -ForegroundColor Cyan
    New-Item -Path $targetBase -ItemType Directory -Force | Out-Null
}

# Find OneDrive paths from registry (more reliable than hardcoded paths)
function Get-OneDrivePaths {
    $oneDrivePaths = @()
    
    # Check current user's OneDrive registry keys
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
                    Write-Verbose "Found OneDrive path from registry: $($userFolder.UserFolder)"
                }
            }
            catch {
                Write-Verbose "Could not read registry key: $keyPath"
            }
        }
    }
    
    # Fallback: Check common OneDrive locations in user profiles
    $userFolders = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -notin @("Administrator", "Public", "Default", "defaultuser0", "All Users") }
    
    foreach ($userFolder in $userFolders) {
        # Find any folder starting with "OneDrive" (handles "OneDrive", "OneDrive - Company", etc.)
        $potentialOneDrives = Get-ChildItem -Path $userFolder.FullName -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "OneDrive*" }
        
        foreach ($od in $potentialOneDrives) {
            if ($od.FullName -notin $oneDrivePaths) {
                $oneDrivePaths += $od.FullName
                Write-Verbose "Found OneDrive path from filesystem: $($od.FullName)"
            }
        }
    }
    
    return $oneDrivePaths | Select-Object -Unique
}

# Language-agnostic recursive search for the module
function Find-ModuleInOneDrive {
    param (
        [string[]]$OneDrivePaths,
        [string]$ModuleName = "pwsh-neofetch"
    )
    
    foreach ($oneDrivePath in $OneDrivePaths) {
        Write-Host "Searching in: $oneDrivePath" -ForegroundColor Yellow
        
        # Search for Modules folders containing pwsh-neofetch
        # This handles any language: Documents, ドキュメント, 文件, 문서, Documenti, etc.
        try {
            $modulePaths = Get-ChildItem -Path $oneDrivePath -Recurse -Directory -ErrorAction SilentlyContinue -Depth 4 |
                Where-Object { $_.Name -eq $ModuleName } |
                Where-Object { 
                    # Verify it's in a Modules folder (PowerShell or WindowsPowerShell)
                    $_.Parent.Name -eq "Modules" -and 
                    ($_.Parent.Parent.Name -eq "PowerShell" -or $_.Parent.Parent.Name -eq "WindowsPowerShell")
                }
            
            foreach ($modulePath in $modulePaths) {
                # Verify it contains the expected module files
                $psd1 = Join-Path $modulePath.FullName "pwsh-neofetch.psd1"
                $psm1 = Join-Path $modulePath.FullName "pwsh-neofetch.psm1"
                
                if ((Test-Path $psd1) -and (Test-Path $psm1)) {
                    Write-Host "  Found valid module at: $($modulePath.FullName)" -ForegroundColor Green
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

Write-Host "Searching for 'pwsh-neofetch' module in OneDrive folders..." -ForegroundColor Cyan
Write-Host "(This may take a moment for large OneDrive folders)" -ForegroundColor Gray

$oneDrivePaths = Get-OneDrivePaths

if ($oneDrivePaths.Count -eq 0) {
    Write-Host "No OneDrive folders found." -ForegroundColor Yellow
    Write-Host "If you're experiencing module path issues, try reinstalling from PowerShell Gallery:" -ForegroundColor Cyan
    Write-Host "  Install-Module -Name pwsh-neofetch -Force" -ForegroundColor White
    exit 0
}

Write-Host "Found $($oneDrivePaths.Count) OneDrive location(s) to search." -ForegroundColor Cyan

$sourcePath = Find-ModuleInOneDrive -OneDrivePaths $oneDrivePaths

if ($sourcePath) {
    Write-Host "`nModule found at: $sourcePath" -ForegroundColor Green
    
    if (Test-Path -Path $targetModuleFolder) {
        Write-Host "Target module folder already exists: $targetModuleFolder" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite it? (Y/N)"
        
        if ($overwrite -notmatch '^[Yy]') {
            Write-Host "Operation cancelled." -ForegroundColor Red
            exit 0
        }
        
        $backupFolder = "$targetModuleFolder.backup"
        Write-Host "Creating backup of existing module folder: $backupFolder" -ForegroundColor Cyan
        if (Test-Path -Path $backupFolder) {
            Remove-Item -Path $backupFolder -Recurse -Force
        }
        Rename-Item -Path $targetModuleFolder -NewName (Split-Path -Leaf $backupFolder)
    }
    
    Write-Host "Copying module to: $targetModuleFolder" -ForegroundColor Cyan
    Copy-Item -Path $sourcePath -Destination $targetModuleFolder -Recurse -Force
    
    Write-Host "`nModule successfully relocated!" -ForegroundColor Green
    Write-Host "You can now use 'neofetch' command from any PowerShell prompt." -ForegroundColor Cyan
    
    # Verify the copy
    $verifyPsd1 = Join-Path $targetModuleFolder "pwsh-neofetch.psd1"
    if (Test-Path $verifyPsd1) {
        try {
            $manifest = Test-ModuleManifest -Path $verifyPsd1 -ErrorAction Stop -WarningAction SilentlyContinue
            Write-Host "Verified: Module version $($manifest.Version) installed." -ForegroundColor Green
        }
        catch {
            Write-Warning "Module copied but manifest validation failed: $_"
        }
    }
}
else {
    Write-Host "`nModule 'pwsh-neofetch' not found in any OneDrive folder." -ForegroundColor Red
    Write-Host "`nSearched locations:" -ForegroundColor Yellow
    foreach ($path in $oneDrivePaths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    Write-Host "`nPossible solutions:" -ForegroundColor Cyan
    Write-Host "  1. Install from PowerShell Gallery: Install-Module -Name pwsh-neofetch" -ForegroundColor White
    Write-Host "  2. Run the direct installer: .\direct-installer.ps1" -ForegroundColor White
}