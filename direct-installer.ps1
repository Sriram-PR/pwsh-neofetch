<#
.SYNOPSIS
    Installer for PowerShell Neofetch
.DESCRIPTION
    This script downloads and installs PowerShell Neofetch system-wide,
    allowing you to run 'neofetch' from any PowerShell prompt.
.NOTES
    Author: PowerShell Neofetch Installer
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$RepoUrl = "https://github.com/Sriram-PR/pwsh-neofetch.git",
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "main",
    
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "$env:USERPROFILE\Tools\pwsh-neofetch",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoProfile = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$AsModule = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Function to show colorful messages
function Write-ColorMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Setup function for error handling
function Start-Installation {
    Write-ColorMessage "`n===== PowerShell Neofetch Installer =====" -ForegroundColor Cyan
    Write-ColorMessage "This script will install PowerShell Neofetch and make it available system-wide.`n" -ForegroundColor Cyan

    # Check if Git is installed
    $gitInstalled = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
    
    if (-not $gitInstalled) {
        Write-ColorMessage "Git is not installed. We'll download the script directly instead." -ForegroundColor Yellow
        $useGit = $false
    } else {
        $useGit = $true
        Write-ColorMessage "Git is installed. We'll use it to clone the repository." -ForegroundColor Green
    }
    
    # Create installation directory if it doesn't exist
    if (Test-Path -Path $InstallPath) {
        if ($Force) {
            Write-ColorMessage "Removing existing installation directory..." -ForegroundColor Yellow
            Remove-Item -Path $InstallPath -Recurse -Force
        } else {
            Write-ColorMessage "Installation directory already exists at: $InstallPath" -ForegroundColor Yellow
            $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
            if ($overwrite -eq "y") {
                Remove-Item -Path $InstallPath -Recurse -Force
            } else {
                Write-ColorMessage "Installation aborted. Use existing installation or specify a different path." -ForegroundColor Red
                return
            }
        }
    }
    
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-ColorMessage "Created installation directory at: $InstallPath" -ForegroundColor Green
    
    # Download or clone the repository
    Push-Location $InstallPath
    try {
        if ($useGit) {
            Write-ColorMessage "Cloning the PowerShell Neofetch repository..." -ForegroundColor Cyan
            $gitOutput = git clone $RepoUrl --branch $Branch --single-branch .
            if ($LASTEXITCODE -ne 0) {
                throw "Git clone failed. Please check the repository URL and your internet connection."
            }
        } else {
            # Direct download as fallback if git isn't available
            Write-ColorMessage "Downloading PowerShell Neofetch..." -ForegroundColor Cyan
            
            # Extract repo owner and name from the URL
            if ($RepoUrl -match "github\.com\/([^\/]+)\/([^\/\.]+)") {
                $owner = $matches[1]
                $repo = $matches[2]
                
                # GitHub URL for zip download
                $zipUrl = "https://github.com/$owner/$repo/archive/refs/heads/$Branch.zip"
                $zipPath = Join-Path $env:TEMP "$repo-$Branch.zip"
                
                try {
                    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
                    
                    # Extract the zip file
                    Write-ColorMessage "Extracting files..." -ForegroundColor Cyan
                    Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force
                    
                    # Move the contents to the install directory
                    $extractedFolder = Join-Path $env:TEMP "$repo-$Branch"
                    Get-ChildItem -Path $extractedFolder | Copy-Item -Destination $InstallPath -Recurse -Force
                    
                    # Clean up
                    Remove-Item -Path $zipPath -Force
                    Remove-Item -Path $extractedFolder -Recurse -Force
                    
                } catch {
                    throw "Failed to download or extract the repository: $_"
                }
            } else {
                throw "Invalid GitHub URL format. Please provide a valid GitHub repository URL."
            }
        }
    } catch {
        Write-ColorMessage "Error: $_" -ForegroundColor Red
        Pop-Location
        return
    }
    Pop-Location
    
    Write-ColorMessage "PowerShell Neofetch has been downloaded successfully!" -ForegroundColor Green
    
    # Verify the script exists in the standalone directory
    $neofetchScriptPath = Join-Path $InstallPath "standalone-script\pwsh-neofetch.ps1"
    if (-not (Test-Path $neofetchScriptPath)) {
        Write-ColorMessage "Error: Could not find the pwsh-neofetch.ps1 script in the downloaded repository." -ForegroundColor Red
        Write-ColorMessage "Please check the repository URL and structure." -ForegroundColor Red
        return
    }
    
    # Copy the script to the root directory for simplicity
    Copy-Item -Path $neofetchScriptPath -Destination $InstallPath
    $mainScriptPath = Join-Path $InstallPath "pwsh-neofetch.ps1"
    
    # Set execution policy if needed
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
        Write-ColorMessage "Setting execution policy to RemoteSigned for current user..." -ForegroundColor Yellow
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-ColorMessage "Execution policy updated!" -ForegroundColor Green
    }
    
    # Set up as PowerShell module if requested
    if ($AsModule) {
        Install-AsModule $mainScriptPath
    }
    
    # Update profile if requested
    if (-not $NoProfile) {
        Update-PowerShellProfile
    }
    
    # Final instructions
    Write-ColorMessage "`n===== Installation Complete! =====" -ForegroundColor Green
    Write-ColorMessage "You can now use PowerShell Neofetch by typing 'neofetch' in any PowerShell window.`n" -ForegroundColor Green
    
    $runNow = Read-Host "Would you like to run neofetch now? (y/n)"
    if ($runNow -eq 'y') {
        Write-ColorMessage "`nRunning neofetch for the first time..." -ForegroundColor Cyan
        & $mainScriptPath
    } else {
        Write-ColorMessage "`nYou can run PowerShell Neofetch by typing 'neofetch' in a new PowerShell window." -ForegroundColor Cyan
    }
}

function Install-AsModule {
    param(
        [string]$ScriptPath
    )
    
    Write-ColorMessage "`nSetting up PowerShell module..." -ForegroundColor Cyan
    
    # Create module directory
    $modulesPath = "$env:USERPROFILE\Documents\PowerShell\Modules"
    $winPSModulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
    
    # Check for PowerShell Core vs Windows PowerShell
    $isPSCore = $PSVersionTable.PSEdition -eq "Core"
    
    if ($isPSCore) {
        $targetModulesPath = $modulesPath
    } else {
        $targetModulesPath = $winPSModulesPath
    }
    
    # Create both module paths for compatibility
    New-Item -ItemType Directory -Path $modulesPath -Force | Out-Null
    New-Item -ItemType Directory -Path $winPSModulesPath -Force | Out-Null
    
    $moduleDir = Join-Path $targetModulesPath "Neofetch"
    New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
    
    # Create module file
    $moduleFile = Join-Path $moduleDir "Neofetch.psm1"
    $moduleContent = @"
<#
.SYNOPSIS
    PowerShell Neofetch Module
.DESCRIPTION
    This module provides the neofetch command for PowerShell.
#>

function Invoke-Neofetch {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$Arguments
    )
    
    # Initialize parameter hashtable
    `$params = @{}
    
    # Process arguments to create proper parameter hashtable
    for (`$i = 0; `$i -lt `$Arguments.Count; `$i++) {
        `$arg = `$Arguments[`$i]
        
        # Check if it's a parameter (starts with dash)
        if (`$arg.StartsWith('-')) {
            # Get parameter name without the dash
            `$paramName = `$arg.TrimStart('-')
            
            # Check if next arg exists and isn't a parameter
            if ((`$i + 1) -lt `$Arguments.Count -and -not `$Arguments[`$i + 1].StartsWith('-')) {
                # This is a parameter with a value
                `$params[`$paramName] = `$Arguments[`$i + 1]
                `$i++ # Skip the next argument since we've processed it
            } else {
                # This is a switch parameter
                `$params[`$paramName] = `$true
            }
        }
    }
    
    # Call the script with the properly formatted parameters
    & "$ScriptPath" @params
}

# Export functions
Export-ModuleMember -Function Invoke-Neofetch
# Set up alias
New-Alias -Name neofetch -Value Invoke-Neofetch -Force
Export-ModuleMember -Alias neofetch
"@
    
    Set-Content -Path $moduleFile -Value $moduleContent
    
    # Create module manifest
    $manifestPath = Join-Path $moduleDir "Neofetch.psd1"
    New-ModuleManifest -Path $manifestPath `
        -RootModule "Neofetch.psm1" `
        -ModuleVersion "1.0.0" `
        -Author "PowerShell Neofetch" `
        -Description "PowerShell Neofetch System Information Tool" `
        -PowerShellVersion "5.1" `
        -FunctionsToExport @("Invoke-Neofetch") `
        -AliasesToExport @("neofetch")
    
    # Create symbolic link for compatibility between PS Core and Windows PS
    if ($isPSCore) {
        $winPSModuleDir = Join-Path $winPSModulesPath "Neofetch"
        if (-not (Test-Path $winPSModuleDir)) {
            try {
                New-Item -ItemType Directory -Path $winPSModuleDir -Force | Out-Null
                Copy-Item -Path "$moduleDir\*" -Destination $winPSModuleDir -Recurse -Force
            } catch {
                Write-ColorMessage "Note: Could not create Windows PowerShell compatibility files. This is not critical." -ForegroundColor Yellow
            }
        }
    } else {
        $psModuleDir = Join-Path $modulesPath "Neofetch"
        if (-not (Test-Path $psModuleDir)) {
            try {
                New-Item -ItemType Directory -Path $psModuleDir -Force | Out-Null
                Copy-Item -Path "$moduleDir\*" -Destination $psModuleDir -Recurse -Force
            } catch {
                Write-ColorMessage "Note: Could not create PowerShell Core compatibility files. This is not critical." -ForegroundColor Yellow
            }
        }
    }
    
    Write-ColorMessage "PowerShell module created successfully!" -ForegroundColor Green
}

function Update-PowerShellProfile {
    Write-ColorMessage "`nUpdating PowerShell profile..." -ForegroundColor Cyan
    
    # Determine which profile to use
    $isPSCore = $PSVersionTable.PSEdition -eq "Core"
    
    if ($isPSCore) {
        $profilePath = $PROFILE.CurrentUserAllHosts
    } else {
        $profilePath = $PROFILE
    }
    
    # Create profile if it doesn't exist
    if (-not (Test-Path -Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
        Write-ColorMessage "Created PowerShell profile at: $profilePath" -ForegroundColor Green
    }
    
    # Check if module import already exists in profile
    $profileContent = Get-Content -Path $profilePath -ErrorAction SilentlyContinue
    $importExists = $profileContent -match "Import-Module\s+Neofetch"
    
    if (-not $importExists) {
        $profileUpdate = @"

# PowerShell Neofetch
if (Get-Module -ListAvailable -Name Neofetch) {
    Import-Module Neofetch
} else {
    Write-Warning "Neofetch module not found. You may need to reinstall."
}
"@
        Add-Content -Path $profilePath -Value $profileUpdate
        Write-ColorMessage "Updated PowerShell profile to import the Neofetch module." -ForegroundColor Green
    } else {
        Write-ColorMessage "PowerShell profile already contains the Neofetch module import." -ForegroundColor Yellow
    }
}

# Run the installation
try {
    Start-Installation
} catch {
    Write-ColorMessage "Critical error during installation: $_" -ForegroundColor Red
    Write-ColorMessage "Installation failed. Please try again or install manually." -ForegroundColor Red
}