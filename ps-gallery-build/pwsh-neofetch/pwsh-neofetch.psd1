@{
    RootModule = 'pwsh-neofetch.psm1'
    
    ModuleVersion = '1.3.0'
    
    GUID = '4dc7d7d4-9924-4545-bd71-99932a7f6f8a'
    
    Author = 'Sriram PR'
    
    Description = 'A feature-rich PowerShell implementation of the popular Neofetch system information tool for Windows.'
    
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @('Invoke-Neofetch')
    
    CmdletsToExport = @()
    
    VariablesToExport = @()
    
    AliasesToExport = @('neofetch')
    
    PrivateData = @{
        PSData = @{
            Tags = @('windows', 'neofetch', 'system-info', 'terminal')
            
            LicenseUri = 'https://github.com/Sriram-PR/pwsh-neofetch/blob/main/LICENSE'
            
            ProjectUri = 'https://github.com/Sriram-PR/pwsh-neofetch/tree/main'
            
            ReleaseNotes = 'v1.3.0 - Renamed function to Invoke-Neofetch (alias preserved), added -AsObject for structured output, -WhatIf/-Confirm support, ASCII art validation, language-agnostic module relocator, removed benchmark feature, consolidated defaults. See CHANGELOG.md for details.'
        }
    }
}