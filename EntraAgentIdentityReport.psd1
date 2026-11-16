@{
    RootModule        = 'EntraAgentIdentityReport.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '8f2a6c1b-4d3e-4a7f-9c2d-1e5b7a9f3c40'
    Author            = 'Charles Jenkins'
    CompanyName       = 'Charles Jenkins'
    Copyright         = '(c) 2026 Charles Jenkins. Publie sous licence MIT.'
    Description       = 'Inventaire en lecture seule des identites d agents Microsoft Entra Agent ID via Microsoft Graph.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('Microsoft.Graph.Authentication')
    FunctionsToExport = @('Get-EntraAgentIdentityInventory', 'Export-EntraAgentIdentityReport')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData = @{
        PSData = @{
            Tags         = @('Copilot', 'Agent', 'Entra', 'Graph', 'Inventory', 'ReadOnly')
            LicenseUri   = 'https://opensource.org/license/mit'
            ProjectUri   = 'https://trivium365.com/blog/sortir-agents-copilot-mode-pilote-cinq-decisions-30-jours/'
            ReleaseNotes = 'Version 1.0.0. Premiere version.'
        }
    }
}
