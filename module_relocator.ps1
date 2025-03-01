$targetBase = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
$targetModuleFolder = Join-Path -Path $targetBase -ChildPath "pwsh-neofetch"

if (-not (Test-Path -Path $targetBase)) {
    Write-Host "Creating target directory: $targetBase" -ForegroundColor Cyan
    New-Item -Path $targetBase -ItemType Directory -Force | Out-Null
}

$userFolders = Get-ChildItem -Path "C:\Users" -Directory | 
    Where-Object { $_.Name -ne "Administrator" -and $_.Name -ne "Public" -and $_.Name -ne "Default" -and $_.Name -ne "defaultuser0" }

Write-Host "Searching for 'pwsh-neofetch' module in OneDrive folders..." -ForegroundColor Cyan

$moduleFound = $false
$sourcePath = $null

foreach ($userFolder in $userFolders) {
    $userName = $userFolder.Name
    Write-Host "Checking user: $userName" -ForegroundColor Yellow
    
    $oneDrivePath = Join-Path -Path $userFolder.FullName -ChildPath "OneDrive"
    
    if (Test-Path -Path $oneDrivePath) {
        Write-Host "  OneDrive folder found for user $userName" -ForegroundColor Yellow
        
        $modulesPathsToCheck = @(
            [PSCustomObject]@{
                Description = "English Documents - WindowsPowerShell path"
                Path = Join-Path -Path $oneDrivePath -ChildPath "Documents\WindowsPowerShell\Modules"
            },
            [PSCustomObject]@{
                Description = "English Documents - PowerShell path"
                Path = Join-Path -Path $oneDrivePath -ChildPath "Documents\PowerShell\Modules"
            },
            [PSCustomObject]@{
                Description = "Japanese Documents - WindowsPowerShell path"
                Path = Join-Path -Path $oneDrivePath -ChildPath "ドキュメント\WindowsPowerShell\Modules"
            },
            [PSCustomObject]@{
                Description = "Japanese Documents - PowerShell path"
                Path = Join-Path -Path $oneDrivePath -ChildPath "ドキュメント\PowerShell\Modules"
            }
        )
        
        foreach ($pathInfo in $modulesPathsToCheck) {
            if (Test-Path -Path $pathInfo.Path) {
                Write-Host "  Found Modules folder at: $($pathInfo.Path)" -ForegroundColor Yellow
                
                $modulePath = Join-Path -Path $pathInfo.Path -ChildPath "pwsh-neofetch"
                Write-Host "  Checking for module at: $modulePath" -ForegroundColor Yellow
                
                if (Test-Path -Path $modulePath) {
                    Write-Host "  Found module in $($pathInfo.Description)!" -ForegroundColor Green
                    $sourcePath = $modulePath
                    $moduleFound = $true
                    break
                }
            }
        }
        
        if ($moduleFound) {
            break
        }
    }
    else {
        Write-Host "  No OneDrive folder found for user $userName" -ForegroundColor Yellow
    }
}

if ($moduleFound) {
    Write-Host "Module found at: $sourcePath" -ForegroundColor Green
    
    if (Test-Path -Path $targetModuleFolder) {
        Write-Host "Target module folder already exists: $targetModuleFolder" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite it? (Y/N)"
        
        if ($overwrite -ne "Y") {
            Write-Host "Operation cancelled." -ForegroundColor Red
            exit
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
    
    Write-Host "Module successfully relocated." -ForegroundColor Green
    Write-Host "You can now use 'neofetch' command from any PowerShell prompt." -ForegroundColor Cyan
}
else {
    Write-Host "Module 'pwsh-neofetch' not found in any user's OneDrive folder." -ForegroundColor Red
    Write-Host "Searched the following users:" -ForegroundColor Yellow
    $userFolders | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
}