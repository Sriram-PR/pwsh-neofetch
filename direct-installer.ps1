<#
.SYNOPSIS
    Installer for pwsh-neofetch (GitHub installation method)
.DESCRIPTION
    This script installs pwsh-neofetch from a local clone of the repository.
    For most users, installing from PowerShell Gallery is recommended:
    
        Install-Module -Name pwsh-neofetch
    
    Use this installer when:
    - You cannot access PowerShell Gallery (corporate firewall, air-gapped systems)
    - You want to test a development version
    - You prefer manual installation control
.NOTES
    Author: Sriram PR
    Version: 2.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

$ErrorActionPreference = 'Stop'

# Module configuration
$script:ModuleName = 'pwsh-neofetch'
$script:OldModuleName = 'Neofetch'  # Legacy name from older installer versions

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

function Get-ModuleBasePath {
    # Determine correct module path based on PowerShell edition
    $isPSCore = $PSVersionTable.PSEdition -eq 'Core'
    
    if ($isPSCore) {
        return Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules'
    } else {
        return Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules'
    }
}

function Remove-LegacyModule {
    <#
    .SYNOPSIS
        Removes the old 'Neofetch' module if it exists from previous installer versions
    #>
    
    $legacyPaths = @(
        (Join-Path (Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules') $script:OldModuleName),
        (Join-Path (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules') $script:OldModuleName)
    )
    
    $removed = $false
    
    foreach ($path in $legacyPaths) {
        if (Test-Path $path) {
            Write-ColorMessage "Found legacy '$($script:OldModuleName)' module at: $path" -ForegroundColor Yellow
            Write-ColorMessage "Removing to prevent conflicts..." -ForegroundColor Yellow
            
            try {
                # Unload module if currently loaded
                if (Get-Module -Name $script:OldModuleName -ErrorAction SilentlyContinue) {
                    Remove-Module -Name $script:OldModuleName -Force -ErrorAction SilentlyContinue
                }
                
                Remove-Item -Path $path -Recurse -Force
                Write-ColorMessage "Removed legacy module from: $path" -ForegroundColor Green
                $removed = $true
            }
            catch {
                Write-ColorMessage "Warning: Could not remove legacy module at ${path}: $_" -ForegroundColor Yellow
                Write-ColorMessage "You may need to manually delete this folder to avoid conflicts." -ForegroundColor Yellow
            }
        }
    }
    
    # Clean up legacy profile entries
    $profilePaths = @($PROFILE, $PROFILE.CurrentUserAllHosts) | Where-Object { $_ } | Select-Object -Unique
    
    foreach ($profilePath in $profilePaths) {
        if (Test-Path $profilePath) {
            try {
                $content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
                if ($content -match 'Import-Module\s+Neofetch[^-]') {
                    Write-ColorMessage "Removing legacy module import from profile: $profilePath" -ForegroundColor Yellow
                    $newContent = $content -replace '(?m)^.*Import-Module\s+Neofetch[^-].*$\r?\n?', ''
                    Set-Content -Path $profilePath -Value $newContent.Trim()
                    $removed = $true
                }
            }
            catch {
                Write-ColorMessage "Warning: Could not clean profile ${profilePath}: $_" -ForegroundColor Yellow
            }
        }
    }
    
    return $removed
}

function Install-PwshNeofetch {
    Write-ColorMessage "`n===== pwsh-neofetch Installer =====" -ForegroundColor Cyan
    Write-ColorMessage "Installing from local repository clone.`n" -ForegroundColor Cyan
    
    # Verify we're in the right directory
    $moduleSourcePath = Join-Path $PSScriptRoot 'ps-gallery-build\pwsh-neofetch'
    
    if (-not (Test-Path $moduleSourcePath)) {
        Write-ColorMessage "Error: Module source not found at: $moduleSourcePath" -ForegroundColor Red
        Write-ColorMessage "Please run this script from the root of the pwsh-neofetch repository." -ForegroundColor Red
        Write-ColorMessage "`nAlternatively, install from PowerShell Gallery:" -ForegroundColor Cyan
        Write-ColorMessage "    Install-Module -Name pwsh-neofetch" -ForegroundColor White
        return $false
    }
    
    $manifestPath = Join-Path $moduleSourcePath 'pwsh-neofetch.psd1'
    $modulePath = Join-Path $moduleSourcePath 'pwsh-neofetch.psm1'
    
    if (-not (Test-Path $manifestPath) -or -not (Test-Path $modulePath)) {
        Write-ColorMessage "Error: Module files missing. Expected:" -ForegroundColor Red
        Write-ColorMessage "  - $manifestPath" -ForegroundColor Red
        Write-ColorMessage "  - $modulePath" -ForegroundColor Red
        return $false
    }
    
    # Check for and remove legacy module
    Write-ColorMessage "Checking for legacy installations..." -ForegroundColor Cyan
    $legacyRemoved = Remove-LegacyModule
    if ($legacyRemoved) {
        Write-ColorMessage "Legacy installation cleaned up.`n" -ForegroundColor Green
    } else {
        Write-ColorMessage "No legacy installation found.`n" -ForegroundColor Gray
    }
    
    # Determine target paths
    $moduleBasePath = Get-ModuleBasePath
    $targetModulePath = Join-Path $moduleBasePath $script:ModuleName
    
    # Check if already installed
    if (Test-Path $targetModulePath) {
        if ($Force) {
            Write-ColorMessage "Removing existing installation (--Force specified)..." -ForegroundColor Yellow
            Remove-Item -Path $targetModulePath -Recurse -Force
        } else {
            Write-ColorMessage "Module already installed at: $targetModulePath" -ForegroundColor Yellow
            $overwrite = Read-Host "Overwrite existing installation? (y/N)"
            if ($overwrite -notmatch '^[Yy]') {
                Write-ColorMessage "Installation cancelled." -ForegroundColor Yellow
                return $false
            }
            Remove-Item -Path $targetModulePath -Recurse -Force
        }
    }
    
    # Create module directory
    Write-ColorMessage "Creating module directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $targetModulePath -Force | Out-Null
    
    # Copy module files
    Write-ColorMessage "Copying module files..." -ForegroundColor Cyan
    Copy-Item -Path "$moduleSourcePath\*" -Destination $targetModulePath -Recurse -Force
    
    Write-ColorMessage "Module installed to: $targetModulePath" -ForegroundColor Green
    
    # Install for both PowerShell editions if possible
    $isPSCore = $PSVersionTable.PSEdition -eq 'Core'
    $otherEditionPath = if ($isPSCore) {
        Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules' $script:ModuleName
    } else {
        Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules' $script:ModuleName
    }
    
    if (-not (Test-Path $otherEditionPath)) {
        try {
            $otherEditionParent = Split-Path $otherEditionPath -Parent
            if (-not (Test-Path $otherEditionParent)) {
                New-Item -ItemType Directory -Path $otherEditionParent -Force | Out-Null
            }
            Copy-Item -Path "$moduleSourcePath\*" -Destination $otherEditionPath -Recurse -Force
            Write-ColorMessage "Also installed for other PowerShell edition: $otherEditionPath" -ForegroundColor Green
        }
        catch {
            Write-ColorMessage "Note: Could not install for other PowerShell edition (not critical)." -ForegroundColor Gray
        }
    }
    
    # Verify installation
    Write-ColorMessage "`nVerifying installation..." -ForegroundColor Cyan
    
    # Unload if already loaded
    Remove-Module -Name $script:ModuleName -Force -ErrorAction SilentlyContinue
    
    $importSuccess = $false
    try {
        # Import by path (not name) since module cache may not be refreshed yet
        $manifestPath = Join-Path $targetModulePath 'pwsh-neofetch.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop
        $module = Get-Module -Name $script:ModuleName
        Write-ColorMessage "Module loaded successfully!" -ForegroundColor Green
        Write-ColorMessage "  Name: $($module.Name)" -ForegroundColor White
        Write-ColorMessage "  Version: $($module.Version)" -ForegroundColor White
        $importSuccess = $true
    }
    catch {
        Write-ColorMessage "Warning: Module installed but could not be loaded: $_" -ForegroundColor Yellow
        Write-ColorMessage "Try restarting PowerShell and running: Import-Module $script:ModuleName" -ForegroundColor Yellow
    }
    
    return $importSuccess
}

function Show-PostInstallInfo {
    Write-ColorMessage "`n===== Installation Complete! =====" -ForegroundColor Green
    Write-ColorMessage "You can now use pwsh-neofetch by typing 'neofetch' in any PowerShell window.`n" -ForegroundColor Green
    
    Write-ColorMessage "Quick Start:" -ForegroundColor Cyan
    Write-ColorMessage "  neofetch              # Display system info" -ForegroundColor White
    Write-ColorMessage "  neofetch -minimal     # Minimal output" -ForegroundColor White
    Write-ColorMessage "  neofetch -help        # Show all options" -ForegroundColor White
    Write-ColorMessage "  neofetch -init        # Run configuration wizard`n" -ForegroundColor White
    
    Write-ColorMessage "To update in the future:" -ForegroundColor Cyan
    Write-ColorMessage "  git pull" -ForegroundColor White
    Write-ColorMessage "  .\direct-installer.ps1 -Force`n" -ForegroundColor White
}

# Main execution
try {
    $success = Install-PwshNeofetch
    
    if ($success) {
        Show-PostInstallInfo
        
        $runNow = Read-Host "Run neofetch now? (Y/n)"
        if ($runNow -notmatch '^[Nn]') {
            Write-ColorMessage "`nRunning neofetch...`n" -ForegroundColor Cyan
            neofetch
        }
    }
}
catch {
    Write-ColorMessage "`nCritical error during installation: $_" -ForegroundColor Red
    Write-ColorMessage "Installation failed. Please try again or install from PowerShell Gallery:" -ForegroundColor Red
    Write-ColorMessage "    Install-Module -Name pwsh-neofetch" -ForegroundColor White
    exit 1
}