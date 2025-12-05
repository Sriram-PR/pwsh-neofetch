@{
    RootModule = 'pwsh-neofetch.psm1'
    
    ModuleVersion = '1.2.1'
    
    GUID = '4dc7d7d4-9924-4545-bd71-99932a7f6f8a'
    
    Author = 'Sriram PR'
    
    Description = 'A feature-rich PowerShell implementation of the popular Neofetch system information tool for Windows.'
    
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @('neofetch')
    
    CmdletsToExport = @()
    
    VariablesToExport = '*'
    
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('windows', 'neofetch', 'system-info', 'terminal')
            
            LicenseUri = 'https://github.com/Sriram-PR/pwsh-neofetch/blob/main/LICENSE'
            
            ProjectUri = 'https://github.com/Sriram-PR/pwsh-neofetch/tree/main'
            
            ReleaseNotes = 'v1.2.1 - Refactored codebase, improved CI/CD pipeline, enhanced error handling. See CHANGELOG.md for details.'
        }
    }
}