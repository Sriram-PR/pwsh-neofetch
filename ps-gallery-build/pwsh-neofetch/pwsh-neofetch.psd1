@{
    RootModule = 'pwsh-neofetch.psm1'
    
    ModuleVersion = '1.1.1'
    
    GUID = '4dc7d7d4-9924-4545-bd71-99932a7f6f8a'
    
    Author = 'Sriram PR'
    
    Description = 'A feature-rich PowerShell implementation of the popular Neofetch system information tool for Windows.'
    
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @('neofetch')
    
    CmdletsToExport = @()
    
    VariablesToExport = '*'
    
    AliasesToExport = @()
    
    # ModuleList = @()
    
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('windows', 'neofetch', 'system-info', 'terminal')
            
            LicenseUri = 'https://github.com/Sriram-PR/pwsh-neofetch/blob/main/LICENSE'
            
            ProjectUri = 'https://github.com/Sriram-PR/pwsh-neofetch/tree/main'
            
            # IconUri = ''
            
            ReleaseNotes = 'v1.1 final'
        }
    }
}