@{
    RootModule        = 'MWE.psm1'
    ModuleVersion     = '0.1.0'
    CompatiblePSEditions = @('Core')
    PowerShellVersion = '7.2'

    GUID              = 'fd9e7e33-43a9-4331-aed7-cba9d1e2abbb'

    Author            = 'Peter Tolvaj'

    Description       = 'Modern Workplace Enterprise (MWE) helper module for lab automation.'

    FunctionsToExport = @(*)
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags          = @('MWE', 'EntraID', 'Automation', 'Lab')
            Contact       = 'tolvajp@gmail.com'
            ProjectUri    = ''
            ReleaseNotes  = 'Initial lab version.'
        }
    }
}
