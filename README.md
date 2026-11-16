# EntraAgentIdentityReport

Ce module PowerShell dresse l'inventaire en lecture seule des identités d'agents de Microsoft Entra Agent ID dans ton locataire. Il interroge Microsoft Graph, retourne des objets PowerShell et peut produire un rapport HTML simple.

## Pourquoi maintenant

L'article de Charles Jenkins décrit un angle mort fréquent quand une équipe sort les agents Copilot du mode pilote. Il y a souvent plus d'agents que ce que l'équipe TI arrive à voir ou à gouverner. Microsoft Entra Agent ID donne à chaque agent sa propre identité. Un inventaire est la première étape pour comparer ce que tu crois avoir déployé et ce que ton locataire montre vraiment. Ce module automatise cette lecture sans rien modifier dans le locataire.

## Ce que fait le module

- Il liste les identités d'agents via le point de terminaison GET /servicePrincipals/microsoft.graph.agentIdentity en version 1.0.
- Avec l'option -IncludeBlueprint, il liste aussi les plans d'identités via GET /applications/microsoft.graph.agentIdentityBlueprint en version 1.0.
- Avec l'option -IncludePackage, il liste aussi les paquets du registre des agents via GET /copilot/admin/catalog/packages en version 1.0.
- Il retourne chaque ressource comme un objet PowerShell annoté de la propriété ResourceCategory.
- Il produit au besoin un rapport HTML simple avec la commande Export-EntraAgentIdentityReport.

Le module ne fait aucune écriture dans le locataire. Il n'expose donc aucun paramètre -Apply.

## Prérequis

- PowerShell 5.1 ou une version plus récente.
- Le module Microsoft.Graph installé avec Install-Module Microsoft.Graph. Les commandes Connect-MgGraph et Invoke-MgGraphRequest proviennent du sous-module Microsoft.Graph.Authentication.
- Un compte capable de consentir aux permissions Microsoft Graph listées plus bas.

### Permissions Microsoft Graph et rôles

- AgentIdentity.Read.All pour lister les identités d'agents. C'est la permission minimale.
- AgentIdentityBlueprint.Read.All pour l'option -IncludeBlueprint.
- CopilotPackages.Read.All pour l'option -IncludePackage. Ce point de terminaison porte le libellé préversion. La lecture du registre demande aussi le rôle AI Administrator et son API de gestion des paquets exige une licence Microsoft Agent 365.

## Installation

- Copie les fichiers EntraAgentIdentityReport.psd1 et EntraAgentIdentityReport.psm1 dans un dossier nommé EntraAgentIdentityReport, placé dans un emplacement de ton $env:PSModulePath.
- Importe le module avec Import-Module EntraAgentIdentityReport.

## Exemples d'utilisation

Connexion puis inventaire de base.

```powershell
Connect-MgGraph -Scopes "AgentIdentity.Read.All"
Get-EntraAgentIdentityInventory
```

Inventaire complet avec les plans d'identités et le registre des paquets.

```powershell
Connect-MgGraph -Scopes "AgentIdentity.Read.All","AgentIdentityBlueprint.Read.All","CopilotPackages.Read.All"
Get-EntraAgentIdentityInventory -IncludeBlueprint -IncludePackage
```

Inventaire exporté dans un rapport HTML.

```powershell
Get-EntraAgentIdentityInventory | Export-EntraAgentIdentityReport -Path ".\inventaire-agents.html"
```

Aperçu de l'écriture du rapport sans créer de fichier.

```powershell
Get-EntraAgentIdentityInventory | Export-EntraAgentIdentityReport -Path ".\inventaire-agents.html" -WhatIf
```

## Exemple de sortie

Les valeurs ci-dessous sont fictives et servent seulement d'illustration. Les propriétés exactes dépendent de ce que Microsoft Graph retourne. Le module n'en invente aucune et ajoute seulement la propriété ResourceCategory.

```text
ResourceCategory : AgentIdentity
id               : 11111111-1111-1111-1111-111111111111
displayName      : Agent exemple (valeur fictive)
```

Le décompte apparaît dans le flux d'information.

```text
Identites d agents trouvees : 3
```

## Limites connues

- Microsoft Entra Agent ID est récent et les pages Microsoft Learn qui le décrivent changent souvent. Revérifie les permissions et la disponibilité le jour où tu exécutes le module.
- Le point de terminaison du registre des agents porte le libellé préversion. Son API de gestion des paquets exige une licence Microsoft Agent 365.
- Un inventaire d'identités reste complémentaire à tes rapports d'usage. L'export des interactions Copilot via Microsoft Graph n'inclut pas les agents Copilot Studio.
- Le module suppose une connexion déjà établie avec Connect-MgGraph. Il ne gère pas lui-même l'authentification.
- Les propriétés retournées pour chaque ressource sont celles que Microsoft Graph fournit.

## Article et sources

- Article de Charles Jenkins: https://trivium365.com/blog/sortir-agents-copilot-mode-pilote-cinq-decisions-30-jours/
- Billet From Pilots to Programs sur le Microsoft Copilot Blog: https://techcommunity.microsoft.com/blog/microsoft-copilot-blog/from-pilots-to-programs-a-structured-approach-to-scaling-ai-and-agents-for-real-/4566921
- Page Microsoft Learn sur la migration vers une identité d'agent Entra pour Microsoft Copilot Studio: https://learn.microsoft.com/en-us/microsoft-copilot-studio/govern-migrate-api-entra-agent-identity


## Démonstration en vidéo

https://www.youtube.com/watch?v=KsC3qGduljg
