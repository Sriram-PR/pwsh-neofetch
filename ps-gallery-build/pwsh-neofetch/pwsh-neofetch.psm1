Function Initialize-NeofetchConfig {
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
    
    # Clear screen and show welcome
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
    
    $defaultProfileName = "Windows PowerShell"
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
    $recommendedThreads = [Math]::Min(4, $processorCount)
    
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
        # Setting cache expiration to 0 indicates caching is disabled
        $cacheExpiration = 0
        $cacheExpiration | Out-File -FilePath $cacheExpirationPath -Force
    } else {
        Write-Host "Caching is ${BOLD}enabled${RESET} (system info will be cached between runs)"
        Write-Host "This sets how long (in seconds) before cache is refreshed."
        
        $defaultExpiration = 1800
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
        Write-Host "${BOLD}neofetch -asciiart \"C:\path\to\your\ascii_art.txt\"${RESET}"
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
    
    $testFilePath = Join-Path $env:TEMP "neofetch_disk_test.dat"
    if (Test-Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
        $reloadCount++
    }
    
    return $reloadCount
}
function Invoke-SystemBenchmark {
    param (
        [switch]$Quiet
    )
    
    if (-not $Quiet) {
        Write-Host "`nRunning system benchmark, please wait..." -ForegroundColor Cyan
    }
    
    $benchmarkResults = @{}
    $startTime = Get-Date
    
    # CPU Test
    if (-not $Quiet) {
        Write-Host "Running CPU test..." -ForegroundColor Gray
    }
    
    $cpuStartTime = Get-Date
    $primeCount = 0
    
    function Test-IsPrime {
        param ([int]$number)
        
        if ($number -lt 2) { return $false }
        if ($number -eq 2) { return $true }
        if ($number % 2 -eq 0) { return $false }
        
        $boundary = [math]::Floor([math]::Sqrt($number))
        
        for ($i = 3; $i -le $boundary; $i += 2) {
            if ($number % $i -eq 0) {
                return $false
            }
        }
        
        return $true
    }
    
    for ($i = 3; $i -lt 100000; $i += 2) {
        if (Test-IsPrime -number $i) {
            $primeCount++
        }
    }
    
    $cpuEndTime = Get-Date
    $cpuSeconds = ($cpuEndTime - $cpuStartTime).TotalSeconds
    $cpuScore = [math]::Round(($primeCount / $cpuSeconds) * 10, 2)
    $benchmarkResults.CPU = @{
        Score = $cpuScore
        Time = $cpuSeconds
        Unit = "primes/sec"
        Raw = $primeCount
    }
    
    # Memory Test
    if (-not $Quiet) {
        Write-Host "Running memory test..." -ForegroundColor Gray
    }
    
    $memStartTime = Get-Date
    $arraySize = 100000000
    $memoryArray = New-Object object[] $arraySize
    
    for ($i = 0; $i -lt $arraySize; $i++) {
        $memoryArray[$i] = $i
    }
    
    $sum = 0
    for ($i = 0; $i -lt $arraySize; $i++) {
        $sum += $memoryArray[$i]
    }
    
    $memEndTime = Get-Date
    $memSeconds = ($memEndTime - $memStartTime).TotalSeconds
    $memScore = [math]::Round(($arraySize / $memSeconds) / 10000, 2)
    $benchmarkResults.Memory = @{
        Score = $memScore
        Time = $memSeconds
        Unit = "MB/sec"
        Raw = $arraySize
    }
    
    # Disk Test
    if (-not $Quiet) {
        Write-Host "Running disk test..." -ForegroundColor Gray
    }
    
    $diskStartTime = Get-Date
    $testFilePath = Join-Path $env:TEMP "neofetch_disk_test.dat"
    $testFileSize = 1024MB
    
    $writeTest = Measure-Command {
        $randomData = New-Object byte[] $testFileSize
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $rng.GetBytes($randomData)
        [System.IO.File]::WriteAllBytes($testFilePath, $randomData)
    }
    
    $readTest = Measure-Command {
        $data = [System.IO.File]::ReadAllBytes($testFilePath)
    }
    
    if (Test-Path $testFilePath) {
        Remove-Item -Path $testFilePath -Force
    }
    
    $diskEndTime = Get-Date
    $diskSeconds = ($diskEndTime - $diskStartTime).TotalSeconds
    $writeSpeed = [math]::Round($testFileSize / $writeTest.TotalSeconds / 1MB, 2)
    $readSpeed = [math]::Round($testFileSize / $readTest.TotalSeconds / 1MB, 2)
    $diskScore = [math]::Round(($writeSpeed + $readSpeed) / 2, 2)
    
    $benchmarkResults.Disk = @{
        Score = $diskScore
        WriteSpeed = $writeSpeed
        ReadSpeed = $readSpeed
        Unit = "MB/sec"
        Time = $diskSeconds
    }
    
    # Composite score
    $compositeScore = [math]::Round(
        ($benchmarkResults.CPU.Score * 0.4) + 
        ($benchmarkResults.Memory.Score * 0.3) + 
        ($benchmarkResults.Disk.Score * 0.3), 
    2)
    
    $ratingTable = @{
        "Excellent" = 90
        "Very Good" = 70
        "Good" = 50
        "Average" = 30
        "Below Average" = 15
        "Poor" = 0
    }
    
    $rating = "Poor"
    foreach ($kvp in $ratingTable.GetEnumerator() | Sort-Object -Property Value -Descending) {
        if ($compositeScore -ge $kvp.Value) {
            $rating = $kvp.Key
            break
        }
    }
    
    $benchmarkResults.Composite = @{
        Score = $compositeScore
        Rating = $rating
        Time = (Get-Date) - $startTime
    }
    
    return $benchmarkResults
}

function Show-BenchmarkResults {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Results
    )
    
    $ESC = [char]27
    $RESET = "$ESC[0m"
    $BOLD = "$ESC[1m"
    $CYAN = "$ESC[36m"
    $GREEN = "$ESC[32m"
    $YELLOW = "$ESC[33m"
    $RED = "$ESC[31m"
    
    Write-Host "`n$BOLD${CYAN}System Benchmark Results:$RESET"
    Write-Host ""
    
    Write-Host "$BOLD${CYAN}CPU Performance:$RESET"
    Write-Host "  Score: $($Results.CPU.Score) ($($Results.CPU.Unit))"
    Write-Host "  Time: $($Results.CPU.Time) seconds"
    
    Write-Host "`n$BOLD${CYAN}Memory Performance:$RESET"
    Write-Host "  Score: $($Results.Memory.Score) ($($Results.Memory.Unit))"
    Write-Host "  Time: $($Results.Memory.Time) seconds"
    
    Write-Host "`n$BOLD${CYAN}Disk I/O Performance:$RESET"
    Write-Host "  Score: $($Results.Disk.Score) ($($Results.Disk.Unit))"
    Write-Host "  Write: $($Results.Disk.WriteSpeed) MB/sec"
    Write-Host "  Read: $($Results.Disk.ReadSpeed) MB/sec"
    
    $ratingColor = switch ($Results.Composite.Rating) {
        "Excellent" { $GREEN }
        "Very Good" { $GREEN }
        "Good" { $GREEN }
        "Average" { $YELLOW }
        "Below Average" { $YELLOW }
        "Poor" { $RED }
        default { $RESET }
    }
    
    Write-Host "`n$BOLD${CYAN}Overall Performance:$RESET"
    Write-Host "  Composite Score: $($Results.Composite.Score)"
    Write-Host "  Rating: $ratingColor$($Results.Composite.Rating)$RESET"
    Write-Host "  Total Benchmark Time: $($Results.Composite.Time.TotalSeconds) seconds"
    Write-Host ""
}

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

function Get-SystemInfoFast {
    param (
        [switch]$NoCacheMode,
        [int]$MaxThreadsOverride = 0,
        [int]$CacheExpirationOverride = 0
    )
    
    $cacheableParams = @("OS", "Host", "Kernel", "Resolution", "WM", "CPU", "GPU", "Terminal", "TerminalFont", "Shell")
    
    $threadsSavePath = Join-Path $env:USERPROFILE ".neofetch_threads"
    $maxCoresForPool = 4
    
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
        } catch {}
    }
    
    $maxCoresForPool = [System.Math]::Min($maxCoresForPool, [Environment]::ProcessorCount)
    
    $cachePath = Join-Path $env:TEMP "neofetch_cache.xml"
    
    $cacheExpirationPath = Join-Path $env:USERPROFILE ".neofetch_cache_expiration"
    [int]$cacheExpirationSeconds = 1800
    
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
        catch {}
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
    
    $scriptblocks.Host = {
        $ManufacturerKey = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
        $Manufacturer = (Get-ItemProperty -Path $ManufacturerKey -Name SystemManufacturer -ErrorAction SilentlyContinue).SystemManufacturer
        $Model = (Get-ItemProperty -Path $ManufacturerKey -Name SystemProductName -ErrorAction SilentlyContinue).SystemProductName
        return "$Manufacturer $Model"
    }
    
    $scriptblocks.Uptime = {
        try {
            $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime -ErrorAction Stop
            $BootTime = $OperatingSystem.LastBootUpTime
            $CurrentTime = Get-Date
            $Uptime = $CurrentTime - $BootTime
            return "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) mins"
        }
        catch { return "Unknown" }
    }
    
    $scriptblocks.Packages = {
        try { return (Get-Package | Measure-Object).Count }
        catch { return "Unknown" }
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
        catch { return "Unknown" }
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
        catch { return "Windows Explorer" }
    }
    
    $scriptblocks.Terminal = {
        return $Host.Name
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
            return "Terminal font detection error: $_"
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
        catch { return "Unknown" }
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
        catch { return "Unknown" }
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
        catch { return "Unknown" }
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
        catch { return "No battery detected" }
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

function Get-ASCIIArt {
    param (
        [string]$CustomArtPath,
        [switch]$UseDefaultArt
    )
    
    $asciiSavePath = Join-Path $env:USERPROFILE ".neofetch_ascii"
    $changesMade = $false
    $changeDescription = ""
    $hasColors = $false

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
    Write-Host "  -defaultart          Reset to use the default Windows ASCII art, removing any custom art." -ForegroundColor White
    Write-Host "  -changes             Display information about what configurations have been changed from default." -ForegroundColor White
    Write-Host "  -maxThreads <n>      Limit the maximum number of threads used (default: 4 or number of CPU cores, whichever is lower)." -ForegroundColor White
    Write-Host "  -defaultthreads      Reset to use the default number of threads (4)." -ForegroundColor White
    Write-Host "  -profileName <name>  Set the Windows Terminal profile name to use for font detection." -ForegroundColor White
    Write-Host "                       Common values are 'Windows PowerShell' or 'PowerShell'" -ForegroundColor White
    Write-Host "  -defaultprofile      Reset terminal profile to default (Windows PowerShell)." -ForegroundColor White
    Write-Host "  -cacheExpiration <n> Set the cache expiration period in seconds (default: 1800 = 30 min)." -ForegroundColor White
    Write-Host "  -defaultcache        Reset cache expiration to default (1800 seconds = 30 minutes)." -ForegroundColor White
    Write-Host "  -nocache             Disable caching and force fresh data collection." -ForegroundColor White
    Write-Host "  -minimal             Display a minimal view with only essential system information." -ForegroundColor White
    Write-Host "  -benchmark           Run a system benchmark and display results." -ForegroundColor White
    Write-Host "  -reset               Reset all configuration files and caches to defaults." -ForegroundColor White
    Write-Host "  -help                Display this help message." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  neofetch" -ForegroundColor White
     Write-Host "  neofetch -init" -ForegroundColor White  
    Write-Host "  neofetch -init -Force" -ForegroundColor White
    Write-Host "  neofetch -asciiart `"Drive:\path\to\ascii\art.txt`"" -ForegroundColor White
    Write-Host "  neofetch -defaultart" -ForegroundColor White
    Write-Host "  neofetch profileName `"PowerShell`"" -ForegroundColor White
    Write-Host "  neofetch -changes" -ForegroundColor White
    Write-Host "  neofetch -maxThreads 8" -ForegroundColor White
    Write-Host "  neofetch -benchmark" -ForegroundColor White
    Write-Host ""
}

# Main function that will be exported and called by the alias
function neofetch {
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
        [switch]$benchmark = $false,

        [Parameter(Mandatory=$false)]
        [switch]$reload = $false,

        [Parameter(Mandatory=$false)]
        [switch]$init = $false,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force = $false
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
        $cacheExpiration -or $defaultcache -or $profileName -or $defaultprofile -or $minimal -or $benchmark -or 
        $reload -or $asciiart)) {
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

    if ($benchmark) {
        $benchmarkResults = Invoke-SystemBenchmark
        Show-BenchmarkResults -Results $benchmarkResults
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
            Write-Host "Cache expiration reset to default (1800 seconds = 30 minutes)" -ForegroundColor Cyan
        } else {
            Write-Host "Cache expiration was already set to default" -ForegroundColor Cyan
        }
        return
    }

    if ($defaultprofile) {
        $profileChanged = Reset-ProfileNameDefault
        if ($profileChanged) {
            Write-Host "Profile name reset to default (Windows PowerShell)" -ForegroundColor Cyan
        } else {
            Write-Host "Profile name was already set to default" -ForegroundColor Cyan
        }
        return
    }

    if ($defaultthreads) {
        $threadsChanged = Reset-ThreadsDefault
        if ($threadsChanged) {
            Write-Host "Threads reset to default (4)" -ForegroundColor Cyan
        } else {
            Write-Host "Threads were already set to default" -ForegroundColor Cyan
        }
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
            [int]$defaultExpiration = 1800
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
                Write-Host "  - Custom expiration setting (default is 1800 seconds = 30 minutes)" -ForegroundColor White
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
        [int]$defaultThreads = 4
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
        $defaultProfileName = "Windows PowerShell"
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
    
    Write-Host "Script execution time: $executionTime seconds" -ForegroundColor Gray
}

Export-ModuleMember -Function neofetch
