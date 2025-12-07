<#
.SYNOPSIS
    Pester tests for pwsh-neofetch module
.DESCRIPTION
    Basic test suite to validate module functionality before publish.
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
    
    It 'Exports the neofetch function' {
        $manifest.ExportedFunctions.Keys | Should -Contain 'neofetch'
    }
}

Describe 'Module Import' {
    It 'Module is loaded' {
        $module = Get-Module -Name 'pwsh-neofetch'
        $module | Should -Not -BeNullOrEmpty
    }
    
    It 'neofetch command is available' {
        $command = Get-Command -Name 'neofetch' -ErrorAction SilentlyContinue
        $command | Should -Not -BeNullOrEmpty
    }
    
    It 'neofetch command has expected parameters' {
        $command = Get-Command -Name 'neofetch'
        $command.Parameters.Keys | Should -Contain 'help'
        $command.Parameters.Keys | Should -Contain 'minimal'
        $command.Parameters.Keys | Should -Contain 'benchmark'
        $command.Parameters.Keys | Should -Contain 'changes'
        $command.Parameters.Keys | Should -Contain 'init'
        $command.Parameters.Keys | Should -Contain 'reload'
    }
}

Describe 'Core Functions' {
    Context 'Get-DefaultAsciiArt' {
        It 'Returns an array of strings' {
            # Access the internal function via module scope
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
}

Describe 'System Info Collection' {
    # Note: These tests run on the CI runner, so some values may be different
    # We mainly verify the function doesn't crash and returns expected structure
    
    Context 'Get-SystemInfoFast' {
        BeforeAll {
            # Run with -NoCacheMode to ensure fresh data
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
            # OS should be detected on any Windows system
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
            # Should match pattern like "4.5GiB / 16GiB (28%)"
            $script:sysInfo.Memory | Should -Match '\d+.*GiB.*\d+%'
        }
        
        It 'DiskUsage has expected format' {
            # Should match pattern like "C: 100GB / 500GB (20%)"
            $script:sysInfo.DiskUsage | Should -Match '\d+.*GB.*\d+%'
        }
    }
}

Describe 'Help Parameter' {
    It 'neofetch -help does not throw' {
        { neofetch -help } | Should -Not -Throw
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

Describe 'Benchmark Function' {
    Context 'Invoke-SystemBenchmark' -Skip:($env:SKIP_BENCHMARK_TESTS -eq 'true') {
        # Skip in CI by default as benchmark takes time
        # Set SKIP_BENCHMARK_TESTS=false to run
        
        It 'Returns benchmark results hashtable' {
            $results = & (Get-Module pwsh-neofetch) { 
                Invoke-SystemBenchmark -Quiet 
            }
            
            $results | Should -BeOfType [hashtable]
            $results.Keys | Should -Contain 'CPU'
            $results.Keys | Should -Contain 'Memory'
            $results.Keys | Should -Contain 'Disk'
            $results.Keys | Should -Contain 'Composite'
        }
    }
}