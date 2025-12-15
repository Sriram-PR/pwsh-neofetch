# ============================================================================
# pwsh-neofetch.psm1
# A feature-rich PowerShell implementation of Neofetch for Windows
# ============================================================================

#region Module Configuration

# Module-level error tracking for diagnostics (S8)
$script:LastErrors = @{}

# S12: Consolidated default configuration values
$script:Defaults = @{
    # Cache settings
    CacheExpirationSeconds = 1800
    
    # Threading
    MaxThreads = 4
    
    # Terminal profile
    ProfileName = "Windows PowerShell"
    
    # Live graph settings
    LiveGraphRefreshSeconds = 2
    LiveGraphHeight = 20
    LiveGraphWidth = 80
    
    # ASCII art limits (S9)
    MaxAsciiArtSizeKB = 20
}

#endregion

#region Initialization Functions

function Initialize-NeofetchConfig {
    param (
        [switch]$Force
    )
    
    $ESC = [char]27
    $RESET = "$ESC[0m"
    $BOLD = "$ESC[1m"
    $CYAN = "$ESC[36m"
    $GREEN = "$ESC[32m"
    $YELLOW = "$ESC[33m"
    
    $asciiSavePath = Join-Path $env:USERPROFILE ".neofetch_ascii"
    $threadsSavePath = Join-Path $env:USERPROFILE ".neofetch_threads"
    $cacheExpirationPath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
    $profileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
    
    $isFirstRun = -not(
        (Test-Path $threadsSavePath) -or
        (Test-Path $cacheExpirationPath) -or
        (Test-Path $profileNamePath) -or
        (Test-Path $asciiSavePath)
    )
    
    if (-not $isFirstRun -and -not $Force) {
        Write-Host "`n${BOLD}${YELLOW}Neofetch configuration already exists.${RESET}" -NoNewline
        Write-Host " Use ${BOLD}-init -Force${RESET} to reconfigure anyway."
        Write-Host "Or use ${BOLD}-reload${RESET} to reset all configurations to defaults."
        return
    }
    
    Clear-Host
    Write-Host "`n${BOLD}${CYAN}=============================${RESET}"
    Write-Host "${BOLD}${CYAN} Windows Neofetch Setup${RESET}"
    Write-Host "${BOLD}${CYAN}=============================${RESET}"
    Write-Host "`nWelcome to the ${BOLD}Windows Neofetch${RESET} configuration wizard!"
    Write-Host "This will help you set up your initial preferences."
    Write-Host "You can always change these later with specific commands.`n"
    
    # Terminal Profile Configuration
    Write-Host "${BOLD}${CYAN}[1/4] Terminal Profile Configuration${RESET}"
    Write-Host "This helps identify the correct terminal font and appearance settings."
    Write-Host "Common values: 'Windows PowerShell', 'PowerShell', 'Command Prompt'"
    
    $defaultProfileName = $script:Defaults.ProfileName
    $profileName = Read-Host "Enter your Windows Terminal profile name [Default: $defaultProfileName]"
    
    if ([string]::IsNullOrWhiteSpace($profileName)) {
        $profileName = $defaultProfileName
        Write-Host "Using default profile: ${BOLD}$defaultProfileName${RESET}"
    } else {
        Write-Host "Setting profile to: ${BOLD}$profileName${RESET}"
    }
    
    $profileName | Out-File -FilePath $profileNamePath -Force
    
    # Thread Configuration
    Write-Host "`n${BOLD}${CYAN}[2/4] Thread Configuration${RESET}"
    Write-Host "This sets how many CPU threads Neofetch will use to gather system information."
    Write-Host "Higher values can be faster but may use more system resources."
    
    $processorCount = [Environment]::ProcessorCount
    $recommendedThreads = [Math]::Min($script:Defaults.MaxThreads, $processorCount)
    
    do {
        $maxThreadsInput = Read-Host "Enter max threads (1-$processorCount) [Default: $recommendedThreads]"
        
        if ([string]::IsNullOrWhiteSpace($maxThreadsInput)) {
            $maxThreads = $recommendedThreads
            break
        }
        
        if ([int]::TryParse($maxThreadsInput, [ref]$maxThreads)) {
            if ($maxThreads -ge 1 -and $maxThreads -le $processorCount) {
                break
            }
        }
        
        Write-Host "${YELLOW}Please enter a valid number between 1 and $processorCount${RESET}"
    } while ($true)
    
    Write-Host "Setting max threads to: ${BOLD}$maxThreads${RESET}"
    $maxThreads | Out-File -FilePath $threadsSavePath -Force
    
    # Cache Configuration
    Write-Host "`n${BOLD}${CYAN}[3/4] Cache Configuration${RESET}"
    Write-Host "Neofetch can cache system information to speed up repeated runs."
    
    $enableCache = $true
    $cacheOption = Read-Host "Would you like to enable caching? (Y/n)"
    
    if ($cacheOption -match "^[Nn]") {
        $enableCache = $false
        Write-Host "Caching will be ${BOLD}disabled${RESET} (system info will be gathered fresh each time)"
        $cacheExpiration = 0
        $cacheExpiration | Out-File -FilePath $cacheExpirationPath -Force
    } else {
        Write-Host "Caching is ${BOLD}enabled${RESET} (system info will be cached between runs)"
        Write-Host "This sets how long (in seconds) before cache is refreshed."
        
        $defaultExpiration = $script:Defaults.CacheExpirationSeconds
        $defaultExpirationMin = $defaultExpiration / 60
        
        do {
            $cacheExpirationInput = Read-Host "Enter cache expiration in seconds [Default: $defaultExpiration (${defaultExpirationMin}min)]"
            
            if ([string]::IsNullOrWhiteSpace($cacheExpirationInput)) {
                $cacheExpiration = $defaultExpiration
                break
            }
            
            if ([int]::TryParse($cacheExpirationInput, [ref]$cacheExpiration) -and $cacheExpiration -ge 0) {
                break
            }
            
            Write-Host "${YELLOW}Please enter a valid positive number${RESET}"
        } while ($true)
        
        Write-Host "Setting cache expiration to: ${BOLD}$cacheExpiration seconds${RESET}"
        $cacheExpiration | Out-File -FilePath $cacheExpirationPath -Force
    }
    
    # ASCII Art Configuration
    Write-Host "`n${BOLD}${CYAN}[4/4] ASCII Art Configuration${RESET}"
    Write-Host "Neofetch displays an ASCII art logo next to system information."
    Write-Host "You can use the default Windows logo or specify a custom art file."
    
    $useCustomArt = $false
    $customArtOption = Read-Host "Would you like to use custom ASCII art? (y/N)"
    
    if ($customArtOption -match "^[Yy]") {
        $useCustomArt = $true
        Write-Host "`nTo set custom ASCII art, use this command after setup completes:"
        Write-Host "${BOLD}neofetch -asciiart `"C:\path\to\your\ascii_art.txt`"${RESET}"
    } else {
        Write-Host "Using default Windows logo ASCII art"
    }
    
    # Summary
    Write-Host "`n${BOLD}${GREEN}Setup Complete!${RESET}"
    Write-Host "Your Neofetch configuration has been saved with the following settings:"
    Write-Host "${BOLD}Terminal Profile:${RESET} $profileName"
    Write-Host "${BOLD}Max Threads:${RESET} $maxThreads (of $processorCount available)"
    
    if ($cacheExpiration -eq 0) {
        Write-Host "${BOLD}Caching:${RESET} Disabled (fresh data will be gathered each time)"
    } else {
        Write-Host "${BOLD}Caching:${RESET} Enabled"
        Write-Host "${BOLD}Cache Expiration:${RESET} $cacheExpiration seconds ($($cacheExpiration/60) minutes)"
    }
    
    Write-Host "${BOLD}ASCII Art:${RESET} $(if($useCustomArt){"Custom (not set yet)"}else{"Default Windows logo"})"
    
    Write-Host "`n${BOLD}${CYAN}Helpful Commands:${RESET}"
    Write-Host "- ${BOLD}neofetch${RESET} - Run neofetch with your settings"
    Write-Host "- ${BOLD}neofetch -help${RESET} - Show all available commands"
    Write-Host "- ${BOLD}neofetch -changes${RESET} - Display current configuration"
    Write-Host "- ${BOLD}neofetch -reload${RESET} - Reset all settings to defaults"
    
    $runNeofetch = Read-Host "`nRun neofetch now? (Y/n)"
    
    if ($runNeofetch -notmatch "^[Nn]") {
        Write-Host "`nRunning neofetch with your new settings...`n"
        Start-Sleep -Seconds 1
        return $true
    } else {
        return $false
    }
}

function Reset-NeofetchConfiguration {
    $cacheFile = Join-Path $env:TEMP "neofetch_cache.xml"
    $configFiles = @(
        $cacheFile,
        (Join-Path $env:USERPROFILE ".neofetch_ascii"),
        (Join-Path $env:USERPROFILE ".neofetch_cache_expiration"),
        (Join-Path $env:USERPROFILE ".neofetch_threads"),
        (Join-Path $env:USERPROFILE ".neofetch_profile_name")
    )
    
    $reloadCount = 0
    
    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force
            $reloadCount++
        }
    }
    
    # Clear error tracking
    $script:LastErrors = @{}
    
    return $reloadCount
}

#endregion

#region Configuration Helper Functions

function Set-ProfileNameSetting {
    param (
        [string]$ProfileName
    )
    
    $ProfileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
    $ProfileName | Out-File -FilePath $ProfileNamePath -Force
    return $true
}

function Reset-ProfileNameDefault {
    $ProfileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
    if (Test-Path $ProfileNamePath) {
        Remove-Item -Path $ProfileNamePath -Force
        return $true
    }
    return $false
}

function Reset-CacheExpirationDefault {
    $ExpirationSavePath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
    if (Test-Path $ExpirationSavePath) {
        Remove-Item -Path $ExpirationSavePath -Force
        return $true
    }
    return $false
}

function Reset-ThreadsDefault {
    $ThreadsSavePath = Join-Path $env:USERPROFILE ".neofetch_threads"
    if (Test-Path $ThreadsSavePath) {
        Remove-Item -Path $ThreadsSavePath -Force
        return $true
    }
    return $false
}

#endregion

#region System Information Functions

function Get-SystemInfoFast {
    param (
        [switch]$NoCacheMode,
        [int]$MaxThreadsOverride = 0,
        [int]$CacheExpirationOverride = 0
    )
    
    $cacheableParams = @("OS", "Host", "Kernel", "Resolution", "WM", "CPU", "GPU", "Terminal", "TerminalFont", "Shell")
    
    $threadsSavePath = Join-Path $env:USERPROFILE ".neofetch_threads"
    $maxCoresForPool = $script:Defaults.MaxThreads
    
    if ($MaxThreadsOverride -gt 0) {
        $MaxThreadsOverride | Out-File -FilePath $threadsSavePath -Force
        $maxCoresForPool = $MaxThreadsOverride
    } 
    elseif (Test-Path $threadsSavePath) {
        try {
            $savedThreads = [int](Get-Content -Path $threadsSavePath -Raw)
            if ($savedThreads -gt 0) {
                $maxCoresForPool = $savedThreads
            }
        } catch {
            Write-Verbose "Error reading thread configuration: $_"
        }
    }
    
    $maxCoresForPool = [System.Math]::Min($maxCoresForPool, [Environment]::ProcessorCount)
    
    $cachePath = Join-Path $env:TEMP "neofetch_cache.xml"
    
    $cacheExpirationPath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
    [int]$cacheExpirationSeconds = $script:Defaults.CacheExpirationSeconds
    
    if ($CacheExpirationOverride -gt 0) {
        $CacheExpirationOverride | Out-File -FilePath $cacheExpirationPath -Force
        $cacheExpirationSeconds = $CacheExpirationOverride
    }
    elseif (Test-Path $cacheExpirationPath) {
        try {
            $savedExpiration = [int](Get-Content -Path $cacheExpirationPath -Raw)
            if ($savedExpiration -gt 0) {
                $cacheExpirationSeconds = $savedExpiration
            }
        }
        catch {
            Write-Verbose "Error reading cache expiration configuration: $_"
        }
    }
    
    $cacheMaxAge = [TimeSpan]::FromSeconds($cacheExpirationSeconds)
    
    $results = @{}
    
    $useCache = -not $NoCacheMode -and $cacheExpirationSeconds -ne 0
    
    if ($useCache -and (Test-Path $cachePath)) {
        $cacheFile = Get-Item $cachePath
        $cacheAge = (Get-Date) - $cacheFile.LastWriteTime
        
        if ($cacheAge -lt $cacheMaxAge) {
            try {
                $cachedData = Import-Clixml -Path $cachePath
                $useCache = $true
                foreach ($key in $cachedData.Keys) {
                    if ($key -in $cacheableParams) {
                        $results[$key] = $cachedData[$key]
                    }
                }
            }
            catch {
                $useCache = $false
                Write-Verbose "Error reading cache: $_"
            }
        }
        else {
            $useCache = $false
        }
    }
    else {
        $useCache = $false
    }

    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxCoresForPool)
    $runspacePool.Open()
    
    $scriptblocks = @{}
    $runspaces = @{}
    $handles = @{}
    
    $results.UserName = [System.Environment]::UserName
    $results.HostName = $env:COMPUTERNAME
    $results.UserHost = "$([System.Environment]::UserName)@$($env:COMPUTERNAME)"
    
    if (-not $useCache -or -not $results.ContainsKey("OS")) {
        $OSName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
        $OSArch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        $results.OS = "$OSName $OSArch"
    }
    
    if (-not $useCache -or -not $results.ContainsKey("Kernel")) {
        $results.Kernel = [System.Environment]::OSVersion.Version.ToString()
    }
    
    if (-not $useCache -or -not $results.ContainsKey("Shell")) {
        $results.Shell = "PowerShell " + $PSVersionTable.PSVersion.ToString()
    }
    
    # S8: All scriptblocks now include Write-Verbose for error logging
    $scriptblocks.Host = {
        try {
            $ManufacturerKey = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
            $Manufacturer = (Get-ItemProperty -Path $ManufacturerKey -Name SystemManufacturer -ErrorAction SilentlyContinue).SystemManufacturer
            $Model = (Get-ItemProperty -Path $ManufacturerKey -Name SystemProductName -ErrorAction SilentlyContinue).SystemProductName
            return "$Manufacturer $Model"
        }
        catch {
            Write-Verbose "Error getting Host info: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.Uptime = {
        try {
            $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime -ErrorAction Stop
            $BootTime = $OperatingSystem.LastBootUpTime
            $CurrentTime = Get-Date
            $Uptime = $CurrentTime - $BootTime
            return "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) mins"
        }
        catch {
            Write-Verbose "Error getting Uptime: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.Packages = {
        try {
            return (Get-Package -ErrorAction Stop | Measure-Object).Count
        }
        catch {
            Write-Verbose "Error getting Packages count: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.Resolution = {
        try {
            $DisplayInfo = Get-CimInstance -ClassName Win32_VideoController -Property CurrentHorizontalResolution, CurrentVerticalResolution -ErrorAction Stop
            if ($DisplayInfo.CurrentHorizontalResolution) {
                $Resolution = "$($DisplayInfo.CurrentHorizontalResolution)x$($DisplayInfo.CurrentVerticalResolution)"
                return $Resolution -replace "\s", ""
            }
            return "Unknown"
        }
        catch {
            Write-Verbose "Error getting Resolution: $_"
            return "Unknown"
        }
    }

    $scriptblocks.WM = {
        try {
            $ExplorerProcess = Get-Process -Name explorer -ErrorAction SilentlyContinue
            if (-not $ExplorerProcess) {
                if ((Get-WindowsFeature -Name Server-Gui-Shell -ErrorAction SilentlyContinue).InstallState -ne 'Installed') {
                    return "Server Core (No GUI)"
                }
            }
            return "Windows Explorer"
        }
        catch {
            Write-Verbose "Error getting WM: $_"
            return "Windows Explorer"
        }
    }
    
    $scriptblocks.Terminal = {
        try {
            return $Host.Name
        }
        catch {
            Write-Verbose "Error getting Terminal: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.TerminalFont = {
        try {
            $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            $profileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
            $defaultProfileName = "Windows PowerShell"
            
            if (-not (Test-Path $wtSettingsPath)) {
                return "Settings file not found"
            }
            
            $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
            
            $profileNameToUse = $defaultProfileName
            if (Test-Path $profileNamePath) {
                try {
                    $savedProfileName = Get-Content -Path $profileNamePath -Raw
                    if ($savedProfileName -and $savedProfileName.Trim() -ne "") {
                        $profileNameToUse = $savedProfileName.Trim()
                    }
                } catch {
                    Write-Verbose "Error reading profile name: $_"
                }
            }
            
            $profile = $settings.profiles.list | Where-Object { $_.name -eq $profileNameToUse }
            
            if (-not $profile -and $settings.defaultProfile) {
                $defaultGuid = $settings.defaultProfile
                $profile = $settings.profiles.list | Where-Object { $_.guid -eq $defaultGuid }
                $profileNameToUse = if ($profile -and $profile.name) { $profile.name } else { "Default" }
            }
            
            if (-not $profile) {
                return "No matching profile found for profile name '$profileNameToUse'"
            }
            
            $font = if ($profile.font -and $profile.font.face) {
                        $profile.font.face
                    } 
                    elseif ($settings.profiles.defaults -and 
                            $settings.profiles.defaults.font -and 
                            $settings.profiles.defaults.font.face) {
                        $settings.profiles.defaults.font.face
                    } 
                    else {
                        "Unknown"
                    }
            
            return "$font [Profile: $profileNameToUse]"
        }
        catch {
            Write-Verbose "Error getting Terminal Font: $_"
            return "Terminal font detection error"
        }
    }

    $scriptblocks.CPU = {
        try {
            $CPUInfo = Get-CimInstance -ClassName Win32_Processor -Property Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed -ErrorAction Stop
            $CPU = $CPUInfo.Name
            $CPUCores = $CPUInfo.NumberOfCores
            $CPUSpeed = [math]::Round($CPUInfo.MaxClockSpeed / 1000, 1)
            return "$CPU ($CPUCores) @ $CPUSpeed" + "GHz"
        }
        catch {
            Write-Verbose "Error getting CPU info: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.GPU = {
        try {
            $GPUInfoAll = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop
            $DiscreteGPU = $GPUInfoAll | Where-Object { 
                $_.Description -match "NVIDIA|AMD|GeForce|Radeon|Quadro|FirePro|RTX|GTX" 
            } | Select-Object -First 1
            
            if ($DiscreteGPU) {
                return $DiscreteGPU.Description
            }
            else {
                return ($GPUInfoAll | Select-Object -First 1).Description
            }
        }
        catch {
            Write-Verbose "Error getting GPU info: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.GPUMemory = {
        try {
            $nvidiaSmiPath = "C:\Windows\System32\nvidia-smi.exe"
            if (Test-Path $nvidiaSmiPath) {
                $nvidiaSmiOutput = & $nvidiaSmiPath --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
                
                if ($nvidiaSmiOutput) {
                    $memoryInfo = $nvidiaSmiOutput.Trim().Split(',')
                    if ($memoryInfo.Count -ge 2) {
                        $usedVRAM = [int]$memoryInfo[0].Trim()
                        $totalVRAM = [int]$memoryInfo[1].Trim()
                        $vramPercent = [math]::Round(($usedVRAM / $totalVRAM) * 100)
                        
                        return "${usedVRAM}MiB / ${totalVRAM}MiB (${vramPercent}%)"
                    }
                }
            }
            return "Unknown"
        }
        catch {
            Write-Verbose "Error getting GPU Memory: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.Memory = {
        try {
            $MemInfo = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize, FreePhysicalMemory -ErrorAction Stop
            $TotalRAM = [math]::Round($MemInfo.TotalVisibleMemorySize / 1MB, 2)
            $FreeRAM = [math]::Round($MemInfo.FreePhysicalMemory / 1MB, 2)
            $UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
            $RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100)
            return "${UsedRAM}GiB / ${TotalRAM}GiB (${RAMPercent}%)"
        }
        catch {
            Write-Verbose "Error getting Memory info: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.DiskUsage = {
        try {
            $Disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -ErrorAction Stop | 
                    Select-Object Size, FreeSpace
            $DiskTotal = [math]::Round($Disk.Size / 1GB, 2)
            $DiskFree = [math]::Round($Disk.FreeSpace / 1GB, 2)
            $DiskUsed = [math]::Round($DiskTotal - $DiskFree, 2)
            $DiskPercent = [math]::Round(($DiskUsed / $DiskTotal) * 100)
            return "$env:SystemDrive ${DiskUsed}GB / ${DiskTotal}GB (${DiskPercent}%)"
        }
        catch {
            Write-Verbose "Error getting Disk Usage: $_"
            return "Unknown"
        }
    }
    
    $scriptblocks.Battery = {
        try {
            $Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop
            if ($Battery) {
                $BatteryPercent = $Battery.EstimatedChargeRemaining
                
                $ChargingStatus = switch ($Battery.BatteryStatus) {
                    1 { "Discharging" }
                    2 { "AC Power" }
                    3 { "Fully Charged" }
                    4 { "Low" }
                    5 { "Critical" }
                    6 { "Charging" }
                    7 { "Charging and High" }
                    8 { "Charging and Low" }
                    9 { "Charging and Critical" }
                    10 { "Undefined" }
                    11 { "Partially Charged" }
                    default { "Unknown" }
                }
                
                return "$BatteryPercent% [$ChargingStatus]"
            }
            return "No battery detected"
        }
        catch {
            Write-Verbose "Error getting Battery info: $_"
            return "No battery detected"
        }
    }

    $paramsToGather = @()
    
    foreach ($param in $cacheableParams) {
        if (-not $useCache -or -not $results.ContainsKey($param)) {
            $paramsToGather += $param
        }
    }
    
    foreach ($key in $scriptblocks.Keys) {
        if ($key -notin $cacheableParams) {
            $paramsToGather += $key
        }
    }
    
    foreach ($key in $paramsToGather) {
        if ($scriptblocks.ContainsKey($key)) {
            $runspaces[$key] = [powershell]::Create().AddScript($scriptblocks[$key])
            $runspaces[$key].RunspacePool = $runspacePool
            $handles[$key] = $runspaces[$key].BeginInvoke()
        }
    }

    foreach ($key in $runspaces.Keys) {
        $results[$key] = $runspaces[$key].EndInvoke($handles[$key])
        $runspaces[$key].Dispose()
    }

    if ($paramsToGather.Where({ $_ -in $cacheableParams }).Count -gt 0) {
        try {
            $cacheData = @{}
            foreach ($key in $cacheableParams) {
                if ($results.ContainsKey($key)) {
                    $cacheData[$key] = $results[$key]
                }
            }
            
            $cacheData | Export-Clixml -Path $cachePath -Force
        }
        catch {
            Write-Verbose "Error saving cache: $_"
        }
    }

    $runspacePool.Close()
    $runspacePool.Dispose()

    return @{
        UserHost = $results.UserHost
        OS = $results.OS
        Host = $results.Host
        Kernel = $results.Kernel
        Uptime = $results.Uptime
        Packages = $results.Packages
        Shell = $results.Shell
        Resolution = $results.Resolution
        WM = $results.WM
        Terminal = $results.Terminal
        TerminalFont = $results.TerminalFont
        CPU = $results.CPU
        GPU = $results.GPU
        GPUMemory = $results.GPUMemory
        Memory = $results.Memory
        DiskUsage = $results.DiskUsage
        Battery = $results.Battery
    }
}

#endregion

#region Display Functions

function Get-ColorBlocks {
    $ESC = [char]27
    $RESET = "$ESC[0m"
    $row1 = "$ESC[40m   $RESET$ESC[41m   $RESET$ESC[42m   $RESET$ESC[43m   $RESET$ESC[44m   $RESET$ESC[45m   $RESET$ESC[46m   $RESET$ESC[47m   $RESET"
    $row2 = "$ESC[100m   $RESET$ESC[101m   $RESET$ESC[102m   $RESET$ESC[103m   $RESET$ESC[104m   $RESET$ESC[105m   $RESET$ESC[106m   $RESET$ESC[107m   $RESET"
    
    return @($row1, $row2)
}

function Get-DefaultAsciiArt {
    return @(	
        "                           .oodMMMM",
        "                  .oodMMMMMMMMMMMMM",
        "      ..oodMMM  MMMMMMMMMMMMMMMMMMM",
        "oodMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "``^^^^^^MMMMMMM  MMMMMMMMMMMMMMMMMMM",
        "      ````````^^^^  ^^MMMMMMMMMMMMMMMMM",
        "                     ````````^^^^^^MMMM"
    )
}

#endregion

#region Live Monitoring Functions

function Show-LiveUsageGraphs {
    param (
        [ValidateRange(0.1, 60)]
        [double]$RefreshRateSeconds = $script:Defaults.LiveGraphRefreshSeconds,
        [int]$GraphHeightParam = $script:Defaults.LiveGraphHeight,
        [int]$GraphWidthParam = $script:Defaults.LiveGraphWidth
    )
    
    $ESC = [char]27
    $RESET = "$ESC[0m"
    $BOLD = "$ESC[1m"
    $MAGENTA = "$ESC[35m"
    $CpuLineColor = "$ESC[36m" 
    $RamLineColor = "$ESC[32m" 
    $GpuUtilLineColor = "$ESC[31m" 
    $VramUtilLineColor = "$ESC[33m"
    $AxisColor = "$ESC[90m"
    $GridColor = "$ESC[38;5;237m"
    $CpuBarColor = $CpuLineColor
    $RamBarColor = $RamLineColor
    $GpuBarColor = $GpuUtilLineColor
    $VramBarColor = $VramUtilLineColor
    $ErrorColor = "$ESC[31m"
    $GRAY = "$ESC[90m"

    $maxHistoryLength = $GraphWidthParam * 2
    [System.Collections.Generic.List[double]]$cpuHistory = New-Object System.Collections.Generic.List[double]
    [System.Collections.Generic.List[double]]$ramHistory = New-Object System.Collections.Generic.List[double]
    [System.Collections.Generic.List[double]]$gpuUtilHistory = New-Object System.Collections.Generic.List[double]
    [System.Collections.Generic.List[double]]$vramUtilHistory = New-Object System.Collections.Generic.List[double]

    $summaryBarWidth = 40

    function Set-CursorPosition {
        param ([int]$X, [int]$Y)
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $X, $Y
    }

    function Clear-Line {
        param([int]$Y)
        Set-CursorPosition 0 $Y
        Write-Host (" " * $Host.UI.RawUI.BufferSize.Width) -NoNewline
        Set-CursorPosition 0 $Y
    }

    function Format-UsageBar {
        param (
            [string]$Label,
            [double]$Percentage,
            [string]$AdditionalInfo = "",
            [int]$PassedBarWidth
        )
        $Percentage = [Math]::Max(0, [Math]::Min(100, $Percentage))
        $filledChars = [Math]::Round(($Percentage / 100) * $PassedBarWidth)
        $emptyChars = $PassedBarWidth - $filledChars
        
        $barColorToUse = "$ESC[32m"
        switch -Wildcard ($Label) {
            "*CPU*" { $barColorToUse = $CpuBarColor }
            "*RAM*" { $barColorToUse = $RamBarColor }
            "*GPU*" { $barColorToUse = $GpuBarColor }
            "*VRAM*" { $barColorToUse = $VramBarColor }
        }
        if ($Percentage -ge 90) { $barColorToUse = $ErrorColor } 
        elseif ($Percentage -ge 70) { if($Label -notmatch "CPU"){ $barColorToUse = $VramUtilLineColor }}
        
        $paddedLabel = "{0,-10}" -f $Label
        $barSegment = "[" + ($barColorToUse + ("█" * $filledChars) + $RESET) + ("░" * $emptyChars) + "]"
        $percentStr = "{0,5:N1}%" -f $Percentage
        $result = "${paddedLabel}: ${barSegment} ${percentStr}"
        if ($AdditionalInfo) { $result += " ($AdditionalInfo)" }
        return $result
    }

    function Get-LiveCpuUsage {
        try {
            $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue
            return [Math]::Round($cpuLoad, 1)
        } catch {
            Write-Verbose "Error getting live CPU usage: $_"
            return $null
        }
    }

    function Get-LiveRamUsage {
        try {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $totalMemoryMB = [Math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
            $freeMemoryMB = [Math]::Round($os.FreePhysicalMemory / 1KB, 0)
            $usedMemoryMB = $totalMemoryMB - $freeMemoryMB
            $ramPercentUsed = if ($totalMemoryMB -gt 0) { [Math]::Round(($usedMemoryMB / $totalMemoryMB) * 100, 1) } else { 0 }
            return @{ TotalMB = $totalMemoryMB; UsedMB = $usedMemoryMB; Percent = $ramPercentUsed }
        } catch {
            Write-Verbose "Error getting live RAM usage: $_"
            return $null
        }
    }

    function Get-LiveNvidiaGpuUsage {
        try {
            $smiPath = if (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe") {
                "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
            } elseif (Test-Path "C:\Windows\System32\nvidia-smi.exe") {
                "C:\Windows\System32\nvidia-smi.exe"
            } else { return $null }
            
            $output = & $smiPath --query-gpu=utilization.gpu,memory.total,memory.used --format=csv,noheader,nounits 2>$null
            if (-not $output) { return $null }
            $stats = $output.Trim() -split ','
            if ($stats.Count -lt 3) { return $null }

            $gpuUtilization = [int]($stats[0].Trim())
            $vramTotalMB = [int]$stats[1].Trim()
            $vramUsedMB = [int]$stats[2].Trim()
            $vramPercentUsed = if ($vramTotalMB -gt 0) { [Math]::Round(($vramUsedMB / $vramTotalMB) * 100, 1) } else { 0 }
            
            return @{ GPUUtilization = $gpuUtilization; VRAMTotalMB = $vramTotalMB; VRAMUsedMB = $vramUsedMB; VRAMPercent = $vramPercentUsed }
        } catch {
            Write-Verbose "Error getting live NVIDIA GPU usage: $_"
            return $null
        }
    }

    function RenderCharacterLineGraph {
        param (
            [System.Collections.Generic.List[double]]$RenderCpuHistory,
            [System.Collections.Generic.List[double]]$RenderRamHistory,
            [System.Collections.Generic.List[double]]$RenderGpuUtilHistory,
            [System.Collections.Generic.List[double]]$RenderVramUtilHistory,
            [int]$RenderGraphHeight, [int]$RenderGraphWidth,
            [string]$RenderCpuColor, [string]$RenderRamColor, [string]$RenderGpuUtilColor, [string]$RenderVramUtilColor,
            [string]$RenderAxisColor, [string]$RenderGridColor, [string]$RenderResetColor
        )

        $outputGraphLines = [System.Collections.Generic.List[string]]::new()

        $LineChars = @{
            h = '─'; v = '│'; ul = '┐'; ur = '┌'; dl = '┘'; dr = '└'
            cross = '┼'; t_down = '┬'; t_up = '┴'; t_left = '┤'; t_right = '├'
        }
        $cpuPointChar = '*'; $ramPointChar = '+'; $gpuPointChar = '#'; $vramPointChar = '@'
        $gridDotChar = '·'

        $yAxisLabels = @{
            0 = "100% "; ([Math]::Floor($RenderGraphHeight * 0.25)) = " 75% ";
            ([Math]::Floor($RenderGraphHeight * 0.5)) = " 50% "; ([Math]::Floor($RenderGraphHeight * 0.75)) = " 25% ";
            ($RenderGraphHeight -1) = "  0% "
        }
        $yAxisLabelWidth = 6

        $canvas = New-Object 'string[,]' $RenderGraphHeight, $RenderGraphWidth
        $canvasColors = New-Object 'string[,]' $RenderGraphHeight, $RenderGraphWidth

        $horizontalGridPositions = @(0, [Math]::Floor($RenderGraphHeight*0.25), [Math]::Floor($RenderGraphHeight*0.5),
                                     [Math]::Floor($RenderGraphHeight*0.75), ($RenderGraphHeight-1))

        for ($y = 0; $y -lt $RenderGraphHeight; $y++) {
            for ($x = 0; $x -lt $RenderGraphWidth; $x++) {
                $canvas[$y, $x] = " "; $canvasColors[$y,$x] = $RenderResetColor
                if ($horizontalGridPositions -contains $y -and ($x % 10 -eq 0)) {
                    $canvas[$y, $x] = $gridDotChar; $canvasColors[$y,$x] = $RenderGridColor
                }
            }
        }

        function Set-CanvasCharScoped {
            param ([int]$y, [int]$x, [string]$charToDraw, [string]$colorForChar)

            if ($y -lt 0 -or $y -ge $RenderGraphHeight -or $x -lt 0 -or $x -ge $RenderGraphWidth) {
                return
            }

            $existingChar = $canvas[$y, $x]
            $isBlankOrGrid = ($existingChar -eq " " -or $existingChar -eq $gridDotChar)

            if ($isBlankOrGrid) {
                $canvas[$y, $x] = $charToDraw
                $canvasColors[$y, $x] = $colorForChar
                return
            }

            $finalChar = $charToDraw
            $finalColor = $colorForChar
            $merged = $false

            if ($charToDraw -eq $LineChars.h) {
                $merged = $true
                switch ($existingChar) {
                    $LineChars.v      { $finalChar = $LineChars.cross;   $finalColor = $RenderAxisColor; break }
                    $LineChars.ul     { $finalChar = $LineChars.t_down;  break }
                    $LineChars.ur     { $finalChar = $LineChars.t_down;  break }
                    $LineChars.dl     { $finalChar = $LineChars.t_up;    break }
                    $LineChars.dr     { $finalChar = $LineChars.t_up;    break }
                    $LineChars.t_left { $finalChar = $LineChars.cross;  break }
                    $LineChars.t_right { $finalChar = $LineChars.cross;  break }
                    $LineChars.h      { $finalChar = $LineChars.h;      break }
                    $LineChars.t_down { $finalChar = $LineChars.t_down; break }
                    $LineChars.t_up   { $finalChar = $LineChars.t_up;   break }
                    $LineChars.cross  { $finalChar = $LineChars.cross;  break }
                    default           { $merged = $false }
                }
            }
            elseif ($charToDraw -eq $LineChars.v) {
                $merged = $true
                switch ($existingChar) {
                    $LineChars.h      { $finalChar = $LineChars.cross;    $finalColor = $RenderAxisColor; break }
                    $LineChars.ul     { $finalChar = $LineChars.t_left;   break }
                    $LineChars.ur     { $finalChar = $LineChars.t_right;  break }
                    $LineChars.dl     { $finalChar = $LineChars.t_left;   break }
                    $LineChars.dr     { $finalChar = $LineChars.t_right;  break }
                    $LineChars.t_down { $finalChar = $LineChars.cross;   break }
                    $LineChars.t_up   { $finalChar = $LineChars.cross;   break }
                    $LineChars.v       { $finalChar = $LineChars.v;       break }
                    $LineChars.t_left  { $finalChar = $LineChars.t_left;  break }
                    $LineChars.t_right { $finalChar = $LineChars.t_right; break }
                    $LineChars.cross   { $finalChar = $LineChars.cross;   break }
                    default            { $merged = $false }
                }
            }
            elseif (($charToDraw -eq $LineChars.ul) -or ($charToDraw -eq $LineChars.ur) -or
                    ($charToDraw -eq $LineChars.dl) -or ($charToDraw -eq $LineChars.dr)) {
                if ($existingChar -eq $LineChars.h) {
                    if (($charToDraw -eq $LineChars.ul) -or ($charToDraw -eq $LineChars.ur)) { $finalChar = $LineChars.t_down }
                    else { $finalChar = $LineChars.t_up }
                    $merged = $true
                }
                elseif ($existingChar -eq $LineChars.v) {
                    if (($charToDraw -eq $LineChars.ul) -or ($charToDraw -eq $LineChars.dl)) { $finalChar = $LineChars.t_left }
                    else { $finalChar = $LineChars.t_right }
                    $merged = $true
                }
            }

            if (-not $merged) {
                $finalChar = $charToDraw
            }

            $canvas[$y, $x] = $finalChar
            $canvasColors[$y, $x] = $finalColor
        }

        function PlotSingleMetricLine {
            param (
                [System.Collections.Generic.List[double]]$HistoryToPlot,
                [string]$MetricLineColor,
                [int]$PlotGraphHeight, 
                [int]$PlotGraphWidth
            )
            
            $validPoints = @()
            
            for ($x = 0; $x -lt $PlotGraphWidth; $x++) {
                $histIndex = $HistoryToPlot.Count - $PlotGraphWidth + $x
                if ($histIndex -ge 0 -and $histIndex -lt $HistoryToPlot.Count) {
                    $value = $HistoryToPlot[$histIndex]
                    if ($null -ne $value) {
                        $y = [Math]::Floor(($PlotGraphHeight - 1) * (1 - ($value / 100.0)))
                        $y = [Math]::Max(0, [Math]::Min($PlotGraphHeight - 1, $y))
                        $validPoints += @{X = $x; Y = $y; Value = $value}
                    }
                }
            }
            
            if ($validPoints.Count -eq 0) { return }
            
            Set-CanvasCharScoped $validPoints[0].Y $validPoints[0].X $LineChars.h $MetricLineColor
            
            for ($i = 1; $i -lt $validPoints.Count; $i++) {
                $current = $validPoints[$i]
                $previous = $validPoints[$i-1]
                
                if (($current.X - $previous.X) -gt 1) {
                    Set-CanvasCharScoped $current.Y $current.X $LineChars.h $MetricLineColor
                    continue
                }
                
                if ($current.Y -eq $previous.Y) {
                    Set-CanvasCharScoped $current.Y $current.X $LineChars.h $MetricLineColor
                }
                else {
                    $isRising = $current.Y -lt $previous.Y
                    
                    if ($isRising) {
                        Set-CanvasCharScoped $previous.Y $current.X $LineChars.dl $MetricLineColor
                        for ($y_vert = ($current.Y + 1); $y_vert -lt $previous.Y; $y_vert++) {
                            Set-CanvasCharScoped $y_vert $current.X $LineChars.v $MetricLineColor
                        }
                        Set-CanvasCharScoped $current.Y $current.X $LineChars.ur $MetricLineColor
                    }
                    else {
                        Set-CanvasCharScoped $previous.Y $current.X $LineChars.ul $MetricLineColor
                        for ($y_vert = ($previous.Y + 1); $y_vert -lt $current.Y; $y_vert++) {
                            Set-CanvasCharScoped $y_vert $current.X $LineChars.v $MetricLineColor
                        }
                        Set-CanvasCharScoped $current.Y $current.X $LineChars.dr $MetricLineColor
                    }
                }
            }
        }

        PlotSingleMetricLine $RenderVramUtilHistory $RenderVramUtilColor $RenderGraphHeight $RenderGraphWidth
        PlotSingleMetricLine $RenderGpuUtilHistory $RenderGpuUtilColor $RenderGraphHeight $RenderGraphWidth
        PlotSingleMetricLine $RenderRamHistory $RenderRamColor $RenderGraphHeight $RenderGraphWidth
        PlotSingleMetricLine $RenderCpuHistory $RenderCpuColor $RenderGraphHeight $RenderGraphWidth

        for ($y = 0; $y -lt $RenderGraphHeight; $y++) {
            $line = ""; $yLabel = $yAxisLabels[$y]
            if ($yLabel) { $line += "$RenderAxisColor$($yLabel.PadRight($yAxisLabelWidth))$RenderResetColor" }
            else { $line += " " * $yAxisLabelWidth }

            for ($x = 0; $x -lt $RenderGraphWidth; $x++) {
                $charToPrint = $canvas[$y, $x]; $colorForChar = $canvasColors[$y, $x]
                if ($colorForChar -eq $RenderResetColor -and $charToPrint -ne " " -and $charToPrint -eq $gridDotChar){
                    $colorForChar = $RenderGridColor
                } elseif ($colorForChar -eq $RenderResetColor -and $charToPrint -ne " ") {
                     $colorForChar = $RenderAxisColor
                }
                $line += "$colorForChar$charToPrint$RenderResetColor"
            }
            $outputGraphLines.Add($line)
        }

        $xAxisLine = (" " * $yAxisLabelWidth) + "$RenderAxisColor$($LineChars.dl)" + ($LineChars.h * ($RenderGraphWidth-2)) + "$($LineChars.dr)$RenderResetColor"
        if ($RenderGraphWidth -lt 2) {$xAxisLine = (" " * $yAxisLabelWidth) + "$RenderAxisColor$($LineChars.h * $RenderGraphWidth)$RenderResetColor"}
        $outputGraphLines.Add($xAxisLine)

        $timeLabelsLine = (" " * $yAxisLabelWidth)
        $lbl_neg_full = "-$($RenderGraphWidth)s"; $lbl_neg_half = "-$([int]($RenderGraphWidth/2))s"; $lbl_zero = "0s "
        $timeLabelLength = $RenderGraphWidth
        $availableSpaceForLabels = $timeLabelLength - $lbl_zero.Length
        $pos_neg_full = 0
        $pos_neg_half = [Math]::Max(0, [int]($availableSpaceForLabels / 2) - [int]($lbl_neg_half.Length / 2))

        $tempTimeLine = (" " * $timeLabelLength)
        function InsertString {param($original, $insert, $position)
            return $original.Substring(0, $position) + $insert + $original.Substring($position + $insert.Length)
        }
        if (($pos_neg_full + $lbl_neg_full.Length) -le $timeLabelLength) {
            $tempTimeLine = InsertString $tempTimeLine $lbl_neg_full $pos_neg_full
        }
        if (($pos_neg_half + $lbl_neg_half.Length) -le $timeLabelLength) {
             $tempTimeLine = InsertString $tempTimeLine $lbl_neg_half $pos_neg_half
        }
        $tempTimeLine = InsertString $tempTimeLine $lbl_zero ([Math]::Max(0, $timeLabelLength - $lbl_zero.Length))

        $timeLabelsLine += "$RenderAxisColor$tempTimeLine$RenderResetColor"
        $outputGraphLines.Add($timeLabelsLine)

        $legend = (" " * $yAxisLabelWidth) + "$RenderCpuColor$($cpuPointChar) CPU$RenderResetColor  " +
                                          "$RenderRamColor$($ramPointChar) RAM$RenderResetColor  " +
                                          "$RenderGpuUtilColor$($gpuPointChar) GPU$RenderResetColor  " +
                                          "$RenderVramUtilColor$($vramPointChar) VRAM$RenderResetColor"
        $outputGraphLines.Add($legend)
        return $outputGraphLines
    }

    # S7 FIX: Initialize variables BEFORE try block to ensure they're available in finally
    $psHost = $null
    $originalBufferWidth = 0
    $originalBufferHeight = 0

    try {
        [Console]::CursorVisible = $false
        
        # Assign after try starts (but variables exist in scope)
        $psHost = Get-Host
        $originalBufferWidth = $psHost.UI.RawUI.BufferSize.Width
        $originalBufferHeight = $psHost.UI.RawUI.BufferSize.Height
        
        $lastUpdateTime = [DateTime]::MinValue
        $smiPath1 = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
        $smiPath2 = "C:\Windows\System32\nvidia-smi.exe"
        $nvidiaSmiPathFound = (Test-Path $smiPath1) -or (Test-Path $smiPath2)
        $continueLoop = $true
        
        $requiredBufferWidth = $GraphWidthParam + 15
        $requiredBufferHeight = $GraphHeightParam + 15
        if ($originalBufferWidth -lt $requiredBufferWidth -or $originalBufferHeight -lt $requiredBufferHeight) {
            try {
                $newBufferSize = $psHost.UI.RawUI.BufferSize
                $newBufferSize.Width = [Math]::Max($originalBufferWidth, $requiredBufferWidth)
                $newBufferSize.Height = [Math]::Max($originalBufferHeight, $requiredBufferHeight)
                $psHost.UI.RawUI.BufferSize = $newBufferSize
            } catch {
                Write-Warning "Could not resize console buffer. Graph may not display optimally."
            }
        }
        
        $totalDisplayLines = $GraphHeightParam + 12 
        
        Clear-Host
        $titleLine = "${BOLD}${MAGENTA}Live System Character Graph (Press 'q' or ESC to quit)${RESET}"
        Write-Host $titleLine
        Write-Host ("-" * ($GraphWidthParam + 15))
        
        for ($i = 0; $i -lt $totalDisplayLines; $i++) {
            Write-Host ""
        }
        
        $startY = 2
        
        while ($continueLoop) {
            $now = Get-Date
            
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true) 
                if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q' -or $key.Key -eq 'Escape') {
                    $continueLoop = $false; break
                }
            }
            
            if (($now - $lastUpdateTime).TotalSeconds -ge $RefreshRateSeconds) {
                $lastUpdateTime = $now
                
                $cpuUsageVal = Get-LiveCpuUsage
                $ramUsageInfoVal = Get-LiveRamUsage
                $gpuUsageInfoVal = if ($nvidiaSmiPathFound) { Get-LiveNvidiaGpuUsage } else { $null }

                $cpuHistory.Add($cpuUsageVal)
                if ($ramUsageInfoVal) { $ramHistory.Add($ramUsageInfoVal.Percent) } else { $ramHistory.Add($null) }
                if ($gpuUsageInfoVal) { 
                    $gpuUtilHistory.Add($gpuUsageInfoVal.GPUUtilization)
                    $vramUtilHistory.Add($gpuUsageInfoVal.VRAMPercent)
                } else {
                    $gpuUtilHistory.Add($null); $vramUtilHistory.Add($null)
                }

                foreach($arr in @($cpuHistory, $ramHistory, $gpuUtilHistory, $vramUtilHistory)) {
                    while ($arr.Count -gt $maxHistoryLength) { $arr.RemoveAt(0) }
                }

                $displayLines = [System.Collections.Generic.List[string]]::new()

                $graphCanvasLines = RenderCharacterLineGraph -RenderCpuHistory $cpuHistory `
                    -RenderRamHistory $ramHistory -RenderGpuUtilHistory $gpuUtilHistory -RenderVramUtilHistory $vramUtilHistory `
                    -RenderGraphHeight $GraphHeightParam -RenderGraphWidth $GraphWidthParam `
                    -RenderCpuColor $CpuLineColor -RenderRamColor $RamLineColor -RenderGpuUtilColor $GpuUtilLineColor -RenderVramUtilColor $VramUtilLineColor `
                    -RenderAxisColor $AxisColor -RenderGridColor $GridColor -RenderResetColor $RESET
                
                foreach ($graphLine in $graphCanvasLines) {
                    $displayLines.Add($graphLine)
                }

                $displayLines.Add("") 

                $displayLines.Add("${BOLD}Current Usage:${RESET}")
                if ($null -ne $cpuUsageVal) { $displayLines.Add((Format-UsageBar -Label "CPU" -Percentage $cpuUsageVal -PassedBarWidth $summaryBarWidth)) } 
                else { $displayLines.Add("CPU:      ${ErrorColor}Error fetching data${RESET}") }
                
                if ($null -ne $ramUsageInfoVal) { $displayLines.Add((Format-UsageBar -Label "RAM" -Percentage $ramUsageInfoVal.Percent -AdditionalInfo "$($ramUsageInfoVal.UsedMB)MB/$($ramUsageInfoVal.TotalMB)MB" -PassedBarWidth $summaryBarWidth)) } 
                else { $displayLines.Add("RAM:      ${ErrorColor}Error fetching data${RESET}") }
                
                if ($nvidiaSmiPathFound) {
                    if ($null -ne $gpuUsageInfoVal) {
                        $displayLines.Add((Format-UsageBar -Label "GPU Util" -Percentage $gpuUsageInfoVal.GPUUtilization -PassedBarWidth $summaryBarWidth))
                        $displayLines.Add((Format-UsageBar -Label "VRAM" -Percentage $gpuUsageInfoVal.VRAMPercent -AdditionalInfo "$($gpuUsageInfoVal.VRAMUsedMB)MB/$($gpuUsageInfoVal.VRAMTotalMB)MB" -PassedBarWidth $summaryBarWidth))
                    } else {
                        $displayLines.Add("GPU Util: ${ErrorColor}NVIDIA SMI Error${RESET}")
                        $displayLines.Add("VRAM:     ${ErrorColor}NVIDIA SMI Error${RESET}")
                    }
                } else {
                    $displayLines.Add("GPU Util: ${GRAY}nvidia-smi N/A${RESET}")
                    $displayLines.Add("VRAM:     ${GRAY}nvidia-smi N/A${RESET}")
                }
                
                $displayLines.Add(("-" * ($GraphWidthParam + 15)))
                $displayLines.Add("${GRAY}Updated: $(Get-Date -Format 'HH:mm:ss')${RESET} | Refresh: ${RefreshRateSeconds}s")

                $currentY = $startY
                foreach ($line in $displayLines) {
                    Set-CursorPosition 0 $currentY
                    Write-Host (" " * $Host.UI.RawUI.BufferSize.Width) -NoNewline
                    Set-CursorPosition 0 $currentY
                    Write-Host $line
                    $currentY++
                }
            }
            Start-Sleep -Milliseconds 50
        }
    }
    finally {
        [Console]::CursorVisible = $true
        
        # S7 FIX: Add null check before accessing $psHost
        if ($null -ne $psHost -and $originalBufferWidth -gt 0 -and $originalBufferHeight -gt 0) {
            try {
                $newBufferSize = $psHost.UI.RawUI.BufferSize
                $newBufferSize.Width = $originalBufferWidth
                $newBufferSize.Height = $originalBufferHeight
                $psHost.UI.RawUI.BufferSize = $newBufferSize
            } catch {
                # Silently ignore - buffer restoration is best-effort
            }
        }
        Clear-Host
    }
}

#endregion

#region ASCII Art Functions

function Get-ASCIIArt {
    param (
        [string]$CustomArtPath,
        [switch]$UseDefaultArt
    )
    
    $asciiSavePath = Join-Path $env:USERPROFILE ".neofetch_ascii"
    $changesMade = $false
    $changeDescription = ""
    $hasColors = $false
    
    # S9: Max file size from defaults (in KB)
    $maxFileSizeKB = $script:Defaults.MaxAsciiArtSizeKB
    $maxFileSizeBytes = $maxFileSizeKB * 1024

    if ($UseDefaultArt) {
        if (Test-Path $asciiSavePath) {
            Remove-Item -Path $asciiSavePath -Force
            $changesMade = $true
            $changeDescription = "Reset to default ASCII art"
        }
        
        $defaultArt = Get-DefaultAsciiArt
        return @{
            Art = $defaultArt
            Changed = $changesMade
            ChangeDescription = $changeDescription
            HasColors = $hasColors
        }
    }

    if ($CustomArtPath -and (Test-Path $CustomArtPath)) {
        # S9: Validate the path and file
        $validationResult = Test-AsciiArtPath -Path $CustomArtPath -MaxSizeBytes $maxFileSizeBytes
        
        if (-not $validationResult.IsValid) {
            # Validation failed - warn and fall back to default
            Write-Warning $validationResult.Message
            Write-Warning "Falling back to default ASCII art."
            
            $defaultArt = Get-DefaultAsciiArt
            return @{
                Art = $defaultArt
                Changed = $false
                ChangeDescription = "Validation failed: $($validationResult.Message)"
                HasColors = $false
            }
        }
        
        # Show warning if path contains traversal (but still allow it per decision #2)
        if ($validationResult.HasTraversal) {
            Write-Warning $validationResult.Message
        }
        
        $art = Get-Content -Path $CustomArtPath -Raw -Encoding UTF8
        $artLines = $art -split "`n" | ForEach-Object { $_.TrimEnd() }
        
        $art | Out-File -FilePath $asciiSavePath -Force -Encoding UTF8
        
        $changesMade = $true
        $changeDescription = "ASCII art changed to use file: $CustomArtPath"
        
        $hasColors = $art -match "\$ESC\["
        
        return @{
            Art = $artLines
            Changed = $changesMade
            ChangeDescription = $changeDescription
            HasColors = $hasColors
        }
    }
    
    if (Test-Path $asciiSavePath) {
        $art = Get-Content -Path $asciiSavePath -Raw -Encoding UTF8
        $artLines = $art -split "`n" | ForEach-Object { $_.TrimEnd() }
        
        $hasColors = $art -match "\$ESC\["
        
        return @{
            Art = $artLines
            Changed = $changesMade
            ChangeDescription = $changeDescription
            HasColors = $hasColors
        }
    }
    
    $defaultArt = Get-DefaultAsciiArt
    return @{
        Art = $defaultArt
        Changed = $changesMade
        ChangeDescription = $changeDescription
        HasColors = $hasColors
    }
}

# S9: New validation function for ASCII art paths
function Test-AsciiArtPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxSizeBytes
    )
    
    $result = @{
        IsValid = $true
        Message = ""
        HasTraversal = $false
    }
    
    # Check if path exists
    if (-not (Test-Path $Path)) {
        $result.IsValid = $false
        $result.Message = "ASCII art file not found: $Path"
        return $result
    }
    
    # Resolve to full path and check if it's a file (not directory)
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        $result.IsValid = $false
        $result.Message = "Unable to resolve path: $Path"
        return $result
    }
    
    $item = Get-Item $resolvedPath.Path -ErrorAction SilentlyContinue
    if (-not $item) {
        $result.IsValid = $false
        $result.Message = "Unable to access file: $Path"
        return $result
    }
    
    if ($item.PSIsContainer) {
        $result.IsValid = $false
        $result.Message = "Path is a directory, not a file: $Path"
        return $result
    }
    
    # Check file size
    if ($item.Length -gt $MaxSizeBytes) {
        $fileSizeKB = [Math]::Round($item.Length / 1024, 2)
        $maxSizeKB = [Math]::Round($MaxSizeBytes / 1024, 2)
        $result.IsValid = $false
        $result.Message = "ASCII art file too large: ${fileSizeKB}KB (maximum: ${maxSizeKB}KB)"
        return $result
    }
    
    # Check for path traversal (warn but don't block per decision #2)
    if ($Path -match '\.\.[\\/]') {
        $result.HasTraversal = $true
        $result.Message = "Path contains directory traversal ('..') - proceeding with caution: $Path"
    }
    
    return $result
}

function Get-ProcessedASCIIArt {
    param (
        [string]$CustomArtPath,
        [switch]$UseDefaultArt
    )
    
    $asciiResult = Get-ASCIIArt -CustomArtPath $CustomArtPath -UseDefaultArt:$UseDefaultArt
    $art = $asciiResult.Art
    $hasColors = $asciiResult.HasColors
    
    $processedArt = @()
    $maxVisibleLength = 0
    
    foreach ($line in $art) {
        $visibleLine = if ($hasColors) { $line -replace "\$ESC\[[0-9;]*m", "" } else { $line }
        $visibleLength = $visibleLine.Length
        if ($visibleLength -gt $maxVisibleLength) {
            $maxVisibleLength = $visibleLength
        }
    }
    
    foreach ($line in $art) {
        $visibleLine = if ($hasColors) { $line -replace "\$ESC\[[0-9;]*m", "" } else { $line }
        $visibleLength = $visibleLine.Length
        $paddingNeeded = $maxVisibleLength - $visibleLength
        
        $processedArt += [PSCustomObject]@{
            OriginalLine = $line
            VisibleLength = $visibleLength
            PaddingNeeded = $paddingNeeded
        }
    }
    
    return @{
        ProcessedArt = $processedArt
        MaxVisibleLength = $maxVisibleLength
        Changed = $asciiResult.Changed
        ChangeDescription = $asciiResult.ChangeDescription
        HasColors = $hasColors
    }
}

#endregion

#region Help Functions

function Show-Usage {
    Write-Host ""
    Write-Host "Windows Neofetch Usage:" -ForegroundColor Cyan
    Write-Host "  neofetch [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -init                Run the configuration wizard to set up neofetch preferences." -ForegroundColor White
    Write-Host "  -Force               Force reconfiguration even if config files already exist (use with -init)." -ForegroundColor White
    Write-Host "  -asciiart <path>     Path to a text file containing ASCII art to use instead of the default Windows logo." -ForegroundColor White
    Write-Host "                       The ASCII art can contain ANSI color codes for colored output." -ForegroundColor White
    Write-Host "                       Maximum file size: $($script:Defaults.MaxAsciiArtSizeKB)KB" -ForegroundColor White
    Write-Host "  -defaultart          Reset to use the default Windows ASCII art, removing any custom art." -ForegroundColor White
    Write-Host "  -changes             Display information about what configurations have been changed from default." -ForegroundColor White
    Write-Host "  -maxThreads <n>      Limit the maximum number of threads used (default: $($script:Defaults.MaxThreads) or number of CPU cores, whichever is lower)." -ForegroundColor White
    Write-Host "  -defaultthreads      Reset to use the default number of threads ($($script:Defaults.MaxThreads))." -ForegroundColor White
    Write-Host "  -profileName <name>  Set the Windows Terminal profile name to use for font detection." -ForegroundColor White
    Write-Host "                       Common values are 'Windows PowerShell' or 'PowerShell'" -ForegroundColor White
    Write-Host "  -defaultprofile      Reset terminal profile to default ($($script:Defaults.ProfileName))." -ForegroundColor White
    Write-Host "  -cacheExpiration <n> Set the cache expiration period in seconds (default: $($script:Defaults.CacheExpirationSeconds) = 30 min)." -ForegroundColor White
    Write-Host "  -defaultcache        Reset cache expiration to default ($($script:Defaults.CacheExpirationSeconds) seconds = 30 minutes)." -ForegroundColor White
    Write-Host "  -nocache             Disable caching and force fresh data collection." -ForegroundColor White
    Write-Host "  -minimal             Display a minimal view with only essential system information." -ForegroundColor White
    Write-Host "  -live                Display live CPU, RAM, GPU, and VRAM usage graphs." -ForegroundColor White
    Write-Host "  -reload              Reset all configuration files and caches to defaults." -ForegroundColor White
    Write-Host "  -help                Display this help message." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  neofetch" -ForegroundColor White
    Write-Host "  neofetch -init" -ForegroundColor White  
    Write-Host "  neofetch -init -Force" -ForegroundColor White
    Write-Host "  neofetch -asciiart `"Drive:\path\to\ascii\art.txt`"" -ForegroundColor White
    Write-Host "  neofetch -defaultart" -ForegroundColor White
    Write-Host "  neofetch -profileName `"PowerShell`"" -ForegroundColor White
    Write-Host "  neofetch -changes" -ForegroundColor White
    Write-Host "  neofetch -maxThreads 8" -ForegroundColor White
    Write-Host "  neofetch -live" -ForegroundColor White
    Write-Host ""
}

#endregion

#region Main Function

# S14: Renamed from 'neofetch' to 'Invoke-Neofetch' for Verb-Noun compliance
function Invoke-Neofetch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$asciiart = $null,
        
        [Parameter(Mandatory=$false)]
        [switch]$help = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$changes = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$defaultart = $false,
        
        [Parameter(Mandatory=$false)]
        [int]$maxThreads = 0,
        
        [Parameter(Mandatory=$false)]
        [switch]$defaultthreads = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$nocache = $false,
        
        [Parameter(Mandatory=$false)]
        [int]$cacheExpiration = 0,
        
        [Parameter(Mandatory=$false)]
        [switch]$defaultcache = $false,
        
        [Parameter(Mandatory=$false)]
        [string]$profileName = $null,
        
        [Parameter(Mandatory=$false)]
        [switch]$defaultprofile = $false,

        [Parameter(Mandatory=$false)]
        [switch]$minimal = $false,

        [Parameter(Mandatory=$false)]
        [switch]$reload = $false,

        [Parameter(Mandatory=$false)]
        [switch]$init = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force = $false,

        [Parameter(Mandatory=$false)]
        [switch]$live = $false
    )

    $ESC = [char]27
    $RESET = "$ESC[0m"
    $BOLD = "$ESC[1m"
    $CYAN = "$ESC[36m"
    $WHITE = "$ESC[37m"

    $configFiles = @(
        (Join-Path $env:USERPROFILE ".neofetch_ascii"),
        (Join-Path $env:USERPROFILE ".neofetch_cache_expiration"),
        (Join-Path $env:USERPROFILE ".neofetch_threads"),
        (Join-Path $env:USERPROFILE ".neofetch_profile_name")
    )
    
    $isFirstRun = -not(
        (Test-Path $configFiles[0]) -or
        (Test-Path $configFiles[1]) -or
        (Test-Path $configFiles[2]) -or
        (Test-Path $configFiles[3])
    )

    if ($isFirstRun -and -not ($help -or $changes -or $defaultart -or $maxThreads -or $defaultthreads -or $nocache -or 
        $cacheExpiration -or $defaultcache -or $profileName -or $defaultprofile -or $minimal -or 
        $reload -or $asciiart -or $live)) {
        Write-Host "${BOLD}${CYAN}First run detected!${RESET} Starting initial setup..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        $init = $true
    }

    if ($init) {
        $runAfterInit = Initialize-NeofetchConfig -Force:$Force
        if (-not $runAfterInit) {
            return
        }
    }

    if ($reload) {
        $reloadCount = Reset-NeofetchConfiguration
        Write-Host "Neofetch has been reset! Cleared $reloadCount configuration and cache files." -ForegroundColor Cyan
        Write-Host "Next run will use default settings and rebuild the cache." -ForegroundColor Cyan
        return
    }

    if ($help) {
        Show-Usage
        return
    }

    if ($profileName) {
        $profileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
        $profileName | Out-File -FilePath $profileNamePath -Force
        Write-Host "Profile name changed to: $profileName" -ForegroundColor Cyan
        return
    }

    if ($cacheExpiration -gt 0) {
        $cacheExpirationPath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
        $cacheExpiration | Out-File -FilePath $cacheExpirationPath -Force
        Write-Host "Cache expiration is set to $cacheExpiration second(s)" -ForegroundColor Cyan
        return
    }

    if ($defaultcache) {
        $cacheChanged = Reset-CacheExpirationDefault
        if ($cacheChanged) {
            Write-Host "Cache expiration reset to default ($($script:Defaults.CacheExpirationSeconds) seconds = 30 minutes)" -ForegroundColor Cyan
        } else {
            Write-Host "Cache expiration was already set to default" -ForegroundColor Cyan
        }
        return
    }

    if ($defaultprofile) {
        $profileChanged = Reset-ProfileNameDefault
        if ($profileChanged) {
            Write-Host "Profile name reset to default ($($script:Defaults.ProfileName))" -ForegroundColor Cyan
        } else {
            Write-Host "Profile name was already set to default" -ForegroundColor Cyan
        }
        return
    }

    if ($defaultthreads) {
        $threadsChanged = Reset-ThreadsDefault
        if ($threadsChanged) {
            Write-Host "Threads reset to default ($($script:Defaults.MaxThreads))" -ForegroundColor Cyan
        } else {
            Write-Host "Threads were already set to default" -ForegroundColor Cyan
        }
        return
    }

    if ($live) {
        Show-LiveUsageGraphs
        return
    }

    # Handle the changes flag
    if ($changes) {
        $asciiResult = Get-ASCIIArt -CustomArtPath $asciiart -UseDefaultArt:$defaultart
        $changesMade = $asciiResult.Changed
        $changeDescription = $asciiResult.ChangeDescription
        
        if ($changesMade) {
            Write-Host "ASCII Changes: $changeDescription" -ForegroundColor Cyan
        } else {
            $asciiSavePath = Join-Path $env:USERPROFILE ".neofetch_ascii"
            if (Test-Path $asciiSavePath) {
                Write-Host "ASCII Changes: ASCII art has been changed from default" -ForegroundColor Cyan
            } else {
                Write-Host "ASCII Changes: None" -ForegroundColor Cyan
            }
        }
        
        $cachePath = Join-Path $env:TEMP "neofetch_cache.xml"
        if (Test-Path $cachePath) {
            $cacheFile = Get-Item $cachePath
            $cacheAge = (Get-Date) - $cacheFile.LastWriteTime
            $cacheMinutes = [Math]::Round($cacheAge.TotalMinutes, 1)
            
            Write-Host "Cache Status: Enabled" -ForegroundColor Cyan
            Write-Host "Cache Location: $cachePath" -ForegroundColor Cyan
            Write-Host "Cache Age: $cacheMinutes minutes old" -ForegroundColor Cyan
            
            $cacheExpirationPath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
            [int]$defaultExpiration = $script:Defaults.CacheExpirationSeconds
            [int]$configuredExpiration = $defaultExpiration
            
            if (Test-Path $cacheExpirationPath) {
                try {
                    $savedExpiration = [int](Get-Content -Path $cacheExpirationPath -Raw)
                    if ($savedExpiration -gt 0) {
                        $configuredExpiration = $savedExpiration
                    }
                } catch {}
            }
            
            $expirationMinutes = [Math]::Round($configuredExpiration / 60, 1)
            Write-Host "Cache Expiration: $configuredExpiration seconds ($expirationMinutes minutes)" -ForegroundColor Cyan
            if ($configuredExpiration -ne $defaultExpiration) {
                Write-Host "  - Custom expiration setting (default is $defaultExpiration seconds = 30 minutes)" -ForegroundColor White
            }
            
            try {
                $cachedData = Import-Clixml -Path $cachePath
                Write-Host "Cached Parameters:" -ForegroundColor Cyan
                foreach ($key in $cachedData.Keys) {
                    Write-Host "  - $key" -ForegroundColor White
                }
            }
            catch {
                Write-Host "Error reading cache: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Cache Status: No cache file found" -ForegroundColor Cyan
        }
        
        $threadsSavePath = Join-Path $env:USERPROFILE ".neofetch_threads"
        [int]$defaultThreads = $script:Defaults.MaxThreads
        [int]$configuredThreads = $defaultThreads
        
        if ($maxThreads -gt 0) {
            $configuredThreads = $maxThreads
        } 
        elseif (Test-Path $threadsSavePath) {
            try {
                $savedThreads = [int](Get-Content -Path $threadsSavePath -Raw)
                if ($savedThreads -gt 0) {
                    $configuredThreads = $savedThreads
                }
            } catch {}
        }
        
        $actualThreads = [System.Math]::Min($configuredThreads, [Environment]::ProcessorCount)
        
        Write-Host "Thread Configuration:" -ForegroundColor Cyan
        Write-Host "  - Configured: $configuredThreads threads" -ForegroundColor White
        if ($configuredThreads -ne $defaultThreads) {
            Write-Host "  - Custom thread setting (default is $defaultThreads)" -ForegroundColor White
        }
        Write-Host "  - Actually using: $actualThreads threads (of $([Environment]::ProcessorCount) available)" -ForegroundColor White
        
        $profileNamePath = Join-Path $env:USERPROFILE ".neofetch_profile_name"
        $defaultProfileName = $script:Defaults.ProfileName
        $configuredProfileName = $defaultProfileName

        if ($profileName) {
            $configuredProfileName = $profileName
        } 
        elseif (Test-Path $profileNamePath) {
            try {
                $savedProfileName = Get-Content -Path $profileNamePath -Raw
                if ($savedProfileName -and $savedProfileName.Trim() -ne "") {
                    $configuredProfileName = $savedProfileName.Trim()
                }
            } catch {}
        }

        Write-Host "Terminal Profile Configuration:" -ForegroundColor Cyan
        Write-Host "  - Profile Name: $configuredProfileName" -ForegroundColor White
        if ($configuredProfileName -ne $defaultProfileName) {
            Write-Host "  - Custom profile setting (default is $defaultProfileName)" -ForegroundColor White
        }
        
        # S8: Show recent errors if any (diagnostic enhancement)
        if ($script:LastErrors.Count -gt 0) {
            Write-Host "`nRecent Errors (for diagnostics):" -ForegroundColor Yellow
            foreach ($key in $script:LastErrors.Keys) {
                Write-Host "  ${key}: $($script:LastErrors[$key])" -ForegroundColor Gray
            }
        }
        
        return
    }

    # Main neofetch display function
    function Show-WindowsNeofetch {
        param (
            [string]$AsciiArtPath,
            [switch]$UseDefaultArt,
            [switch]$UseMinimal,
            [switch]$NoCacheMode,
            [int]$MaxThreadsValue,
            [int]$CacheExpirationValue
        )
        
        $SysInfo = Get-SystemInfoFast -NoCacheMode:$NoCacheMode -MaxThreadsOverride $MaxThreadsValue -CacheExpirationOverride $CacheExpirationValue
        
        $processedAsciiResult = Get-ProcessedASCIIArt -CustomArtPath $AsciiArtPath -UseDefaultArt:$UseDefaultArt
        $processedWindowsLogo = $processedAsciiResult.ProcessedArt
        $maxLogoLineLength = $processedAsciiResult.MaxVisibleLength
        $changesMade = $processedAsciiResult.Changed
        $changeDescription = $processedAsciiResult.ChangeDescription
        $hasColors = $processedAsciiResult.HasColors

        try {
            $consoleWidth = $Host.UI.RawUI.WindowSize.Width
            if ($consoleWidth -le 0) { $consoleWidth = 80 }
        } catch {
            $consoleWidth = 80
        }

        $colorBlocks = Get-ColorBlocks

        $infoLines = @(
            "$BOLD${CYAN}OS:$RESET $($SysInfo.OS)",
            "$BOLD${CYAN}Host:$RESET $($SysInfo.Host)",
            "$BOLD${CYAN}Kernel:$RESET $($SysInfo.Kernel)",
            "$BOLD${CYAN}Uptime:$RESET $($SysInfo.Uptime)",
            "$BOLD${CYAN}Packages:$RESET $($SysInfo.Packages)",
            "$BOLD${CYAN}Shell:$RESET $($SysInfo.Shell)",
            "$BOLD${CYAN}Resolution:$RESET $($SysInfo.Resolution)",
            "$BOLD${CYAN}WM:$RESET $($SysInfo.WM)",
            "$BOLD${CYAN}Terminal:$RESET $($SysInfo.Terminal)",
            "$BOLD${CYAN}Terminal Font:$RESET $($SysInfo.TerminalFont)",
            "$BOLD${CYAN}CPU:$RESET $($SysInfo.CPU)",
            "$BOLD${CYAN}GPU:$RESET $($SysInfo.GPU)",
            "$BOLD${CYAN}GPU Memory:$RESET $($SysInfo.GPUMemory)",
            "$BOLD${CYAN}Memory:$RESET $($SysInfo.Memory)",
            "$BOLD${CYAN}Disk:$RESET $($SysInfo.DiskUsage)",
            "$BOLD${CYAN}Battery:$RESET $($SysInfo.Battery)",
            "",
            $colorBlocks[0],
            $colorBlocks[1]
        )

        $leftPadding = 2
        $spaceBetween = 4

        Write-Host ""

        $header = "$BOLD$CYAN$($SysInfo.UserHost)$RESET"

        if ($UseMinimal) {
            $leftGap = " " * 2

            Write-Host "$leftGap$header"
            Write-Host "$leftGap$CYAN----------------------$RESET"
            $minimalInfos = @(
                "$BOLD${CYAN}Kernel:$RESET $($SysInfo.Kernel)",
                "$BOLD${CYAN}Uptime:$RESET $($SysInfo.Uptime)",
                "$BOLD${CYAN}Packages:$RESET $($SysInfo.Packages)",
                "$BOLD${CYAN}GPU Memory:$RESET $($SysInfo.GPUMemory)",
                "$BOLD${CYAN}Memory:$RESET $($SysInfo.Memory)",
                "$BOLD${CYAN}Battery:$RESET $($SysInfo.Battery)"
            )
        
            foreach ($info in $minimalInfos) {
                Write-Host "$leftGap$info"
            }
            Write-Host ""
            return @{
                changesMade = $changesMade
                changeDescription = $changeDescription
            }
        }
        
        if ($processedWindowsLogo.Count -gt 0) {
            if ($hasColors) {
                $logoLine = $processedWindowsLogo[0].OriginalLine
                $paddingNeeded = $processedWindowsLogo[0].PaddingNeeded
                Write-Host (" " * $leftPadding)$logoLine((" " * ($spaceBetween + $paddingNeeded)) + $header)
            } else {
                $logoLine = $processedWindowsLogo[0].OriginalLine.PadRight($maxLogoLineLength)
                Write-Host (" " * $leftPadding)$logoLine((" " * $spaceBetween) + $header)
            }
            
            $divider = "$CYAN----------------------$RESET"
            
            if ($hasColors -and $processedWindowsLogo.Count -gt 1) {
                $logoLine = $processedWindowsLogo[1].OriginalLine
                $paddingNeeded = $processedWindowsLogo[1].PaddingNeeded
                Write-Host (" " * $leftPadding)$logoLine((" " * ($spaceBetween + $paddingNeeded)) + $divider)
            } elseif ($processedWindowsLogo.Count -gt 1) {
                $logoLine = $processedWindowsLogo[1].OriginalLine.PadRight($maxLogoLineLength)
                Write-Host (" " * $leftPadding)$logoLine((" " * $spaceBetween) + $divider)
            }
            
            for ($i = 0; $i -lt [Math]::Max($processedWindowsLogo.Count - 2, $infoLines.Count); $i++) {
                $logoIndex = $i + 2
                $logoItem = if ($logoIndex -lt $processedWindowsLogo.Count) { $processedWindowsLogo[$logoIndex] } else { $null }
                $logoLine = if ($logoItem) { $logoItem.OriginalLine } else { "" }
                $paddingNeeded = if ($logoItem) { $logoItem.PaddingNeeded } else { $maxLogoLineLength }
                $infoLine = if ($i -lt $infoLines.Count) { $infoLines[$i] } else { "" }
                
                if ($hasColors -and $logoLine) {
                    Write-Host (" " * $leftPadding)$logoLine((" " * ($spaceBetween + $paddingNeeded)) + $infoLine)
                } else {
                    $paddedLogoLine = $logoLine.PadRight($maxLogoLineLength)
                    Write-Host (" " * $leftPadding)$paddedLogoLine((" " * $spaceBetween) + $infoLine)
                }
            }
        } else {
            Write-Host $header
            Write-Host "$CYAN----------------------$RESET"
            foreach ($infoLine in $infoLines) {
                Write-Host $infoLine
            }
        }

        Write-Host ""
        
        return @{
            changesMade = $changesMade
            changeDescription = $changeDescription
        }
    }

    $startTime = Get-Date
    $result = Show-WindowsNeofetch -AsciiArtPath $asciiart -UseDefaultArt:$defaultart -UseMinimal:$minimal -NoCacheMode:$nocache -MaxThreadsValue $maxThreads -CacheExpirationValue $cacheExpiration
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalSeconds
    
    # S17: Consider making this -Verbose only in future (Phase 4)
    Write-Verbose "Script execution time: $executionTime seconds"
}

#endregion

#region Module Exports

# S14: Export the Verb-Noun compliant function and create backward-compatible alias
New-Alias -Name 'neofetch' -Value 'Invoke-Neofetch' -Force -Scope Global

Export-ModuleMember -Function Invoke-Neofetch -Alias neofetch

#endregion