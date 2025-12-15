<#
.SYNOPSIS
    Pester tests for pwsh-neofetch module
.DESCRIPTION
    Test suite to validate module functionality before publish.
    Run with: Invoke-Pester -Path ./tests/
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
    
    It 'Does not export variables (S11)' {
        # VariablesToExport should be empty
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
    
    It 'Does not have benchmark parameter (removed in S10)' {
        $command = Get-Command -Name 'Invoke-Neofetch'
        $command.Parameters.Keys | Should -Not -Contain 'benchmark'
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
    
    Context 'Module Defaults (S12)' {
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

Describe 'ASCII Art Validation (S9)' {
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
            # Create a path with traversal that resolves to the valid file
            # e.g., C:\Temp\neofetch_tests_123\..\neofetch_tests_123\valid_art.txt
            $dirName = Split-Path $script:testDir -Leaf
            $traversalPath = Join-Path $script:testDir "..\\$dirName\valid_art.txt"
            
            $result = & (Get-Module pwsh-neofetch) { 
                Test-AsciiArtPath -Path $args[0] -MaxSizeBytes (20 * 1024) 
            } $traversalPath
            
            # Should be valid but flag the traversal
            $result.IsValid | Should -Be $true
            $result.HasTraversal | Should -Be $true
            $result.Message | Should -Match 'traversal'
        }
    }
}

Describe 'System Info Collection' {
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

Describe 'Help Parameter' {
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
    }
}

Describe 'Backward Compatibility' {
    It 'neofetch alias works the same as Invoke-Neofetch' {
        # Both should resolve to the same command
        $aliasCmd = Get-Command neofetch
        $funcCmd = Get-Command Invoke-Neofetch
        
        $aliasCmd.Definition | Should -Be $funcCmd.Name
    }
}