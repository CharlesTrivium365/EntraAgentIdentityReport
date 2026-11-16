#Requires -Modules Microsoft.Graph.Authentication

<#
    EntraAgentIdentityReport
    Module PowerShell en lecture seule pour inventorier les identites
    d'agents de Microsoft Entra Agent ID a l'aide de Microsoft Graph.
    Aucune ecriture n'est effectuee dans le locataire.
#>

function Get-AgentGraphCollection {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $requestUri = $Uri

    while (-not [string]::IsNullOrWhiteSpace($requestUri)) {
        Write-Verbose -Message "Interrogation de Microsoft Graph : $requestUri"
        $response = Invoke-MgGraphRequest -Method GET -Uri $requestUri -ErrorAction Stop

        if ($response -is [System.Collections.IDictionary]) {
            if ($response.Contains('value') -and $null -ne $response['value']) {
                foreach ($entry in $response['value']) {
                    $results.Add($entry)
                }
            }

            if ($response.Contains('@odata.nextLink')) {
                $requestUri = [string]$response['@odata.nextLink']
            }
            else {
                $requestUri = $null
            }
        }
        else {
            $requestUri = $null
        }
    }

    return $results
}

function ConvertTo-AgentResourceObject {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Resource,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Category
    )

    $ordered = [ordered]@{ ResourceCategory = $Category }

    if ($Resource -is [System.Collections.IDictionary]) {
        foreach ($key in $Resource.Keys) {
            $ordered[[string]$key] = $Resource[$key]
        }
    }
    else {
        $ordered['Value'] = $Resource
    }

    return [pscustomobject]$ordered
}

function Get-EntraAgentIdentityInventory {
<#
.SYNOPSIS
    Inventorie en lecture seule les identites d'agents de Microsoft Entra Agent ID.

.DESCRIPTION
    Interroge Microsoft Graph en version 1.0 pour lister les identites d'agents du
    locataire connecte, puis retourne chaque ressource comme un objet PowerShell
    annote de la propriete ResourceCategory. La fonction n'ecrit rien dans le locataire.

    Une connexion active est requise au prealable avec Connect-MgGraph et la permission
    AgentIdentity.Read.All. Les options -IncludeBlueprint et -IncludePackage exigent des
    permissions supplementaires.

.PARAMETER IncludeBlueprint
    Liste aussi les plans d'identites d'agents a partir du point de terminaison
    GET /applications/microsoft.graph.agentIdentityBlueprint. Exige la permission
    AgentIdentityBlueprint.Read.All.

.PARAMETER IncludePackage
    Liste aussi les paquets du registre des agents a partir du point de terminaison
    GET /copilot/admin/catalog/packages. Point de terminaison en preversion qui exige la
    permission CopilotPackages.Read.All, le role AI Administrator et une licence
    Microsoft Agent 365.

.EXAMPLE
    Connect-MgGraph -Scopes "AgentIdentity.Read.All"
    Get-EntraAgentIdentityInventory

    Liste les identites d'agents du locataire connecte.

.EXAMPLE
    Get-EntraAgentIdentityInventory -IncludeBlueprint -IncludePackage

    Liste les identites d'agents, leurs plans et les paquets du registre.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.NOTES
    Lecture seule. Aucune modification du locataire. Microsoft Entra Agent ID est recent
    et sa documentation change souvent : reverifie permissions et disponibilite le jour
    de l'execution.

.LINK
    https://trivium365.com/blog/sortir-agents-copilot-mode-pilote-cinq-decisions-30-jours/
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [switch] $IncludeBlueprint,

        [Parameter()]
        [switch] $IncludePackage
    )

    $graphBase = 'https://graph.microsoft.com/v1.0'

    $identityUri = "$graphBase/servicePrincipals/microsoft.graph.agentIdentity"
    Write-Verbose -Message 'Lecture des identites des agents.'
    $identities = Get-AgentGraphCollection -Uri $identityUri
    Write-Information -MessageData "Identites d agents trouvees : $($identities.Count)" -InformationAction Continue
    foreach ($identity in $identities) {
        ConvertTo-AgentResourceObject -Resource $identity -Category 'AgentIdentity'
    }

    if ($IncludeBlueprint.IsPresent) {
        $blueprintUri = "$graphBase/applications/microsoft.graph.agentIdentityBlueprint"
        Write-Verbose -Message 'Lecture des plans d identites des agents.'
        $blueprints = Get-AgentGraphCollection -Uri $blueprintUri
        Write-Information -MessageData "Plans d identites trouves : $($blueprints.Count)" -InformationAction Continue
        foreach ($blueprint in $blueprints) {
            ConvertTo-AgentResourceObject -Resource $blueprint -Category 'AgentIdentityBlueprint'
        }
    }

    if ($IncludePackage.IsPresent) {
        $packageUri = "$graphBase/copilot/admin/catalog/packages"
        Write-Verbose -Message 'Lecture du registre des agents.'
        $packages = Get-AgentGraphCollection -Uri $packageUri
        Write-Information -MessageData "Paquets du registre trouves : $($packages.Count)" -InformationAction Continue
        foreach ($package in $packages) {
            ConvertTo-AgentResourceObject -Resource $package -Category 'AgentPackage'
        }
    }
}

function Export-EntraAgentIdentityReport {
<#
.SYNOPSIS
    Produit un rapport HTML simple a partir d'un inventaire d'identites d'agents.

.DESCRIPTION
    Recoit les objets produits par Get-EntraAgentIdentityInventory et ecrit un rapport
    HTML a l'emplacement indique. Le fichier produit est local ; aucune donnee n'est
    renvoyee a Microsoft Graph. L'ecriture passe par ShouldProcess, donc -WhatIf et
    -Confirm sont pris en charge.

.PARAMETER InputObject
    Objet d'inventaire a inclure dans le rapport. Accepte l'entree par pipeline.

.PARAMETER Path
    Chemin du fichier HTML a ecrire.

.EXAMPLE
    Get-EntraAgentIdentityInventory | Export-EntraAgentIdentityReport -Path ".\inventaire-agents.html"

    Ecrit un rapport HTML de l'inventaire courant.

.EXAMPLE
    Get-EntraAgentIdentityInventory | Export-EntraAgentIdentityReport -Path ".\inventaire-agents.html" -WhatIf

    Montre ce qui serait ecrit sans creer le fichier.

.OUTPUTS
    System.IO.FileInfo

.LINK
    https://trivium365.com/blog/sortir-agents-copilot-mode-pilote-cinq-decisions-30-jours/
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject] $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    begin {
        $collected = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $collected.Add($InputObject)
    }

    end {
        $generatedOn = (Get-Date).ToString('yyyy-MM-dd HH:mm')
        $preContent = "<h1>Inventaire des identites d agents</h1><p>Genere le $generatedOn. Donnees en lecture seule.</p>"
        $html = $collected | ConvertTo-Html -Title 'Inventaire des identites d agents' -PreContent $preContent

        if ($PSCmdlet.ShouldProcess($Path, 'Ecrire le rapport HTML')) {
            $html | Out-File -FilePath $Path -Encoding utf8
            Get-Item -LiteralPath $Path
        }
    }
}

Export-ModuleMember -Function 'Get-EntraAgentIdentityInventory', 'Export-EntraAgentIdentityReport'
