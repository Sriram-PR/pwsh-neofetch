<#
.SYNOPSIS
    Pester tests for pwsh-neofetch module
.DESCRIPTION
    Test suite to validate module functionality before publish.
    Run with: Invoke-Pester -Path ./tests/
.NOTES
    Some tests require Windows and are skipped on other platforms.
#>

BeforeAll {
    # Import the module from the build location
    $modulePath = Join-Path $PSScriptRoot '..\ps-gallery-build\pwsh-neofetch\pwsh-neofetch.psd1'
    
    if (-not (Test-Path $modulePath)) {
        throw "Module not found at expected path: $modulePath"
    }
    
    # Remove if already loaded
    Remove-Module -Name 'pwsh-neofetch' -Force -ErrorAction SilentlyContinue
    
    # Import fresh
    Import-Module $modulePath -Force -ErrorAction Stop
    
    # Platform detection for conditional tests
    $script:IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows
}

AfterAll {
    Remove-Module -Name 'pwsh-neofetch' -Force -ErrorAction SilentlyContinue
}

Describe 'Module Manifest' {
    BeforeAll {
        $manifestPath = Join-Path $PSScriptRoot '..\ps-gallery-build\pwsh-neofetch\pwsh-neofetch.psd1'
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop -WarningAction SilentlyContinue
    }
    
    It 'Has a valid manifest' {
        $manifest | Should -Not -BeNullOrEmpty
    }
    
    It 'Has a valid module name' {
        $manifest.Name | Should -Be 'pwsh-neofetch'
    }
    
    It 'Has a valid version number' {
        $manifest.Version | Should -Not -BeNullOrEmpty
        $manifest.Version.ToString() | Should -Match '^\d+\.\d+\.\d+$'
    }
    
    It 'Has a valid GUID' {
        $manifest.GUID | Should -Not -BeNullOrEmpty
        $manifest.GUID | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    }
    
    It 'Has required metadata for PSGallery' {
        $manifest.Description | Should -Not -BeNullOrEmpty
        $manifest.Author | Should -Not -BeNullOrEmpty
    }
    
    It 'Has release notes that match version' {
        $manifest.PrivateData.PSData.ReleaseNotes | Should -Not -BeNullOrEmpty
        $manifest.PrivateData.PSData.ReleaseNotes | Should -Match "v$($manifest.Version)"
    }
    
    It 'Exports Invoke-Neofetch function' {
        $manifest.ExportedFunctions.Keys | Should -Contain 'Invoke-Neofetch'
    }
    
    It 'Exports neofetch alias' {
        $manifest.ExportedAliases.Keys | Should -Contain 'neofetch'
    }
    
    It 'Does not export variables' {
        $manifest.ExportedVariables.Count | Should -Be 0
    }
}

Describe 'Module Import' {
    It 'Module is loaded' {
        $module = Get-Module -Name 'pwsh-neofetch'
        $module | Should -Not -BeNullOrEmpty
    }
    
    It 'Invoke-Neofetch command is available' {
        $command = Get-Command -Name 'Invoke-Neofetch' -ErrorAction SilentlyContinue
        $command | Should -Not -BeNullOrEmpty
        $command.CommandType | Should -Be 'Function'
    }
    
    It 'neofetch alias is available and points to Invoke-Neofetch' {
        $alias = Get-Alias -Name 'neofetch' -ErrorAction SilentlyContinue
        $alias | Should -Not -BeNullOrEmpty
        $alias.Definition | Should -Be 'Invoke-Neofetch'
    }
    
    It 'Invoke-Neofetch has expected parameters' {
        $command = Get-Command -Name 'Invoke-Neofetch'
        $command.Parameters.Keys | Should -Contain 'help'
        $command.Parameters.Keys | Should -Contain 'minimal'
        $command.Parameters.Keys | Should -Contain 'changes'
        $command.Parameters.Keys | Should -Contain 'init'
        $command.Parameters.Keys | Should -Contain 'reload'
        $command.Parameters.Keys | Should -Contain 'live'
    }
    
    It 'Does not have benchmark parameter' {
        $command = Get-Command -Name 'Invoke-Neofetch'
        $command.Parameters.Keys | Should -Not -Contain 'benchmark'
    }
    
    # New parameter test
    It 'Has AsObject parameter' {
        $command = Get-Command -Name 'Invoke-Neofetch'
        $command.Parameters.Keys | Should -Contain 'AsObject'
    }
    
    # SupportsShouldProcess test
    It 'Supports -WhatIf and -Confirm' {
        $command = Get-Command -Name 'Invoke-Neofetch'
        $command.Parameters.Keys | Should -Contain 'WhatIf'
        $command.Parameters.Keys | Should -Contain 'Confirm'
    }
}

Describe 'Core Functions' {
    Context 'Get-DefaultAsciiArt' {
        It 'Returns an array of strings' {
            $art = & (Get-Module pwsh-neofetch) { Get-DefaultAsciiArt }
            $art | Should -Not -BeNullOrEmpty
            $art | Should -BeOfType [string]
            $art.Count | Should -BeGreaterThan 5
        }
    }
    
    Context 'Get-ColorBlocks' {
        It 'Returns two rows of color blocks' {
            $blocks = & (Get-Module pwsh-neofetch) { Get-ColorBlocks }
            $blocks | Should -Not -BeNullOrEmpty
            $blocks.Count | Should -Be 2
        }
        
        It 'Contains ANSI escape sequences' {
            $blocks = & (Get-Module pwsh-neofetch) { Get-ColorBlocks }
            $blocks[0] | Should -Match '\x1b\['
            $blocks[1] | Should -Match '\x1b\['
        }
    }
    
    Context 'Module Defaults' {
        It 'Has consolidated defaults hashtable' {
            $defaults = & (Get-Module pwsh-neofetch) { $script:Defaults }
            $defaults | Should -Not -BeNullOrEmpty
            $defaults | Should -BeOfType [hashtable]
        }
        
        It 'Contains expected default keys' {
            $defaults = & (Get-Module pwsh-neofetch) { $script:Defaults }
            $defaults.Keys | Should -Contain 'CacheExpirationSeconds'
            $defaults.Keys | Should -Contain 'MaxThreads'
            $defaults.Keys | Should -Contain 'ProfileName'
            $defaults.Keys | Should -Contain 'LiveGraphRefreshSeconds'
            $defaults.Keys | Should -Contain 'LiveGraphHeight'
            $defaults.Keys | Should -Contain 'LiveGraphWidth'
            $defaults.Keys | Should -Contain 'MaxAsciiArtSizeKB'
        }
        
        It 'Has correct default values' {
            $defaults = & (Get-Module pwsh-neofetch) { $script:Defaults }
            $defaults.CacheExpirationSeconds | Should -Be 1800
            $defaults.MaxThreads | Should -Be 4
            $defaults.ProfileName | Should -Be "Windows PowerShell"
            $defaults.MaxAsciiArtSizeKB | Should -Be 20
        }
    }
}

Describe 'ASCII Art Validation' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    BeforeAll {
        # Create temp files for testing
        $script:testDir = Join-Path $env:TEMP "neofetch_tests_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        
        # Valid small file
        $script:validFile = Join-Path $script:testDir "valid_art.txt"
        "Test ASCII Art`nLine 2`nLine 3" | Out-File -FilePath $script:validFile -Encoding UTF8
        
        # File that's too large (>20KB)
        $script:largeFile = Join-Path $script:testDir "large_art.txt"
        $largeContent = "X" * (25 * 1024)  # 25KB
        $largeContent | Out-File -FilePath $script:largeFile -Encoding UTF8
        
        # Directory (not a file)
        $script:testSubDir = Join-Path $script:testDir "subdir"
        New-Item -ItemType Directory -Path $script:testSubDir -Force | Out-Null
    }
    
    AfterAll {
        # Cleanup
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Test-AsciiArtPath function' {
        It 'Validates existing file successfully' {
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path $args[0] -MaxSizeBytes (20 * 1024) 
            } $script:validFile
            
            $result.IsValid | Should -Be $true
            $result.HasTraversal | Should -Be $false
        }
        
        It 'Rejects non-existent file' {
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path "C:\nonexistent\file.txt" -MaxSizeBytes (20 * 1024) 
            }
            
            $result.IsValid | Should -Be $false
            $result.Message | Should -Match 'not found'
        }
        
        It 'Rejects file that is too large' {
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path $args[0] -MaxSizeBytes (20 * 1024) 
            } $script:largeFile
            
            $result.IsValid | Should -Be $false
            $result.Message | Should -Match 'too large'
        }
        
        It 'Rejects directory path' {
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path $args[0] -MaxSizeBytes (20 * 1024) 
            } $script:testSubDir
            
            $result.IsValid | Should -Be $false
            $result.Message | Should -Match 'directory'
        }
        
        It 'Detects path traversal but allows it with warning' {
            $dirName = Split-Path $script:testDir -Leaf
            $traversalPath = Join-Path $script:testDir "..\\$dirName\valid_art.txt"
            
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path $args[0] -MaxSizeBytes (20 * 1024) 
            } $traversalPath
            
            $result.IsValid | Should -Be $true
            $result.HasTraversal | Should -Be $true
            $result.Message | Should -Match 'traversal'
        }
    }
}

Describe 'System Info Collection' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    Context 'Get-SystemInfoFast' {
        BeforeAll {
            $script:sysInfo = & (Get-Module pwsh-neofetch) { 
                Get-SystemInfoFast -NoCacheMode 
            }
        }
        
        It 'Returns a hashtable' {
            $script:sysInfo | Should -BeOfType [hashtable]
        }
        
        It 'Contains required keys' {
            $requiredKeys = @(
                'UserHost', 'OS', 'Host', 'Kernel', 'Uptime', 
                'Shell', 'CPU', 'GPU', 'Memory', 'DiskUsage'
            )
            
            foreach ($key in $requiredKeys) {
                $script:sysInfo.Keys | Should -Contain $key
            }
        }
        
        It 'OS is not empty or Unknown' {
            $script:sysInfo.OS | Should -Not -BeNullOrEmpty
            $script:sysInfo.OS | Should -Not -Be 'Unknown'
        }
        
        It 'Kernel version is valid format' {
            $script:sysInfo.Kernel | Should -Match '^\d+\.\d+'
        }
        
        It 'Shell contains PowerShell' {
            $script:sysInfo.Shell | Should -Match 'PowerShell'
        }
        
        It 'UserHost contains @ symbol' {
            $script:sysInfo.UserHost | Should -Match '@'
        }
        
        It 'Memory has expected format' {
            $script:sysInfo.Memory | Should -Match '\d+.*GiB.*\d+%'
        }
        
        It 'DiskUsage has expected format' {
            $script:sysInfo.DiskUsage | Should -Match '\d+.*GB.*\d+%'
        }
    }
}

Describe 'AsObject Parameter' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    Context 'Invoke-Neofetch -AsObject' {
        BeforeAll {
            $script:objectResult = Invoke-Neofetch -AsObject -nocache
        }
        
        It 'Returns a PSCustomObject' {
            $script:objectResult | Should -BeOfType [PSCustomObject]
        }
        
        It 'Has correct PSTypeName' {
            $script:objectResult.PSTypeNames | Should -Contain 'Neofetch.SystemInfo'
        }
        
        It 'Contains all expected properties' {
            $expectedProperties = @(
                'UserName', 'HostName', 'OS', 'Host', 'Kernel', 'Uptime',
                'Packages', 'Shell', 'Resolution', 'WM', 'Terminal',
                'TerminalFont', 'CPU', 'GPU', 'GPUMemory', 'Memory',
                'DiskUsage', 'Battery', 'CollectedAt'
            )
            
            foreach ($prop in $expectedProperties) {
                $script:objectResult.PSObject.Properties.Name | Should -Contain $prop
            }
        }
        
        It 'CollectedAt is a DateTime' {
            $script:objectResult.CollectedAt | Should -BeOfType [DateTime]
        }
        
        It 'Can be converted to JSON' {
            { $script:objectResult | ConvertTo-Json } | Should -Not -Throw
        }
        
        It 'Can be piped to Select-Object' {
            $selected = $script:objectResult | Select-Object OS, CPU, Memory
            $selected.OS | Should -Not -BeNullOrEmpty
            $selected.CPU | Should -Not -BeNullOrEmpty
            $selected.Memory | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'WhatIf Support' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    Context 'Reset-NeofetchConfiguration with -WhatIf' {
        It 'Does not delete files when -WhatIf is specified' {
            # Test the internal function directly
            $fileExists = & (Get-Module pwsh-neofetch) {
                # Create a config file to test
                $testPath = Join-Path $env:USERPROFILE ".neofetch_threads"
                "4" | Out-File $testPath -Force
                
                # Call Reset with WhatIf (suppress output)
                $null = Reset-NeofetchConfiguration -WhatIf
                
                # Return whether file still exists
                return (Test-Path $testPath)
            }
            
            $fileExists | Should -Be $true
            
            # Cleanup
            $threadsPath = Join-Path $env:USERPROFILE ".neofetch_threads"
            if (Test-Path $threadsPath) {
                Remove-Item $threadsPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Help Parameter' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    It 'neofetch -help does not throw' {
        { neofetch -help } | Should -Not -Throw
    }
    
    It 'Invoke-Neofetch -help does not throw' {
        { Invoke-Neofetch -help } | Should -Not -Throw
    }
}

Describe 'Configuration Functions' {
    Context 'Reset-NeofetchConfiguration' {
        It 'Function exists and is callable' {
            $func = & (Get-Module pwsh-neofetch) { Get-Command Reset-NeofetchConfiguration -ErrorAction SilentlyContinue }
            $func | Should -Not -BeNullOrEmpty
        }
        
        It 'Has SupportsShouldProcess attribute' {
            # Check for WhatIf parameter existence (indicates SupportsShouldProcess)
            $hasWhatIf = & (Get-Module pwsh-neofetch) { 
                $cmd = Get-Command Reset-NeofetchConfiguration
                $cmd.Parameters.ContainsKey('WhatIf')
            }
            $hasWhatIf | Should -Be $true
        }
    }
    
    Context 'Initialize-NeofetchConfig' {
        It 'Has SupportsShouldProcess attribute' {
            # Check for WhatIf parameter existence (indicates SupportsShouldProcess)
            $hasWhatIf = & (Get-Module pwsh-neofetch) { 
                $cmd = Get-Command Initialize-NeofetchConfig
                $cmd.Parameters.ContainsKey('WhatIf')
            }
            $hasWhatIf | Should -Be $true
        }
    }
}

Describe 'Backward Compatibility' {
    It 'neofetch alias works the same as Invoke-Neofetch' {
        $aliasCmd = Get-Command neofetch
        $funcCmd = Get-Command Invoke-Neofetch
        
        $aliasCmd.Definition | Should -Be $funcCmd.Name
    }
}

Describe 'Edge Cases' -Skip:(-not ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
    Context 'Empty or null inputs' {
        It 'Handles empty asciiart path gracefully' {
            { Invoke-Neofetch -asciiart "" -help } | Should -Not -Throw
        }
        
        It 'Handles zero maxThreads' {
            { Invoke-Neofetch -maxThreads 0 -help } | Should -Not -Throw
        }
        
        It 'Handles zero cacheExpiration' {
            { Invoke-Neofetch -cacheExpiration 0 -help } | Should -Not -Throw
        }
    }
}