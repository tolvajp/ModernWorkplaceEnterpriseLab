function New-MWEGroupResource {
<#
.SYNOPSIS
Creates a new Entra ID security group based on the specified group intent.

.DESCRIPTION
Creates an Entra ID security group using Microsoft Graph according to the provided
group intent (LICENSE or ENTRAROLE).

The function:
- Builds the group resource definition internally
- Creates the group via New-MgGroup
- Returns the created group object
- Supports -WhatIf / -Confirm semantics via ShouldProcess

This is a lifecycle (imperative) function.
If group creation fails, the original error is re-thrown unchanged.

.PARAMETER Intent
Specifies the group intent.
Supported values:
- LICENSE    : License assignment group
- ENTRAROLE  : Entra role assignment group

.PARAMETER SkuPartNumber
License SKU part number.
Used when Intent is LICENSE.

.PARAMETER RoleName
Entra role display name.
Used when Intent is ENTRAROLE.

.PARAMETER AssignmentType
Role assignment type.
Supported values:
- Active
- Eligible

.PARAMETER WhatIf
Shows what would happen if the command runs.
No group is created.

.PARAMETER Confirm
Prompts for confirmation before creating the group.

.OUTPUTS
Microsoft.Graph.PowerShell.Models.IMicrosoftGraphGroup

.REQUIRED GRAPH SCOPES
The caller must already be authenticated to Microsoft Graph with sufficient permissions.

Delegated:
- Group.ReadWrite.All
- Directory.ReadWrite.All

Application:
- Group.ReadWrite.All
- Directory.ReadWrite.All

.LINK
https://learn.microsoft.com/graph/api/group-post-groups

.EXAMPLE
New-MWEGroupResource `
    -Intent LICENSE `
    -SkuPartNumber ENTERPRISEPREMIUM `
    -AssignmentType Active

Creates a license assignment security group for the specified SKU.

.EXAMPLE
New-MWEGroupResource `
    -Intent ENTRAROLE `
    -RoleName GlobalAdministrator `
    -AssignmentType Eligible

Creates an Entra role-assignable security group for the specified role.

.NOTES
- This function performs a state-changing operation.
- Authentication and authorization are explicit preconditions.
- The function does not establish Graph connections or request permissions.
- Errors are terminating and not wrapped or altered.

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$Intent,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [string]$RoleName,

        [Parameter()]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType
    )
    $ErrorActionPreference = 'Stop'
    $groupSplat = $null

    switch ($Intent) {
        'LICENSE' {
            $displayNameSplat = @{
                Intent        = $Intent
                SkuPartNumber = $SkuPartNumber
            }
            $displayName = Invoke-MWECommand -Command 'Get-MWEGroupDisplayName' -Splat $displayNameSplat

            $groupSplat = @{
                DisplayName        = $displayName
                Description        = "License assignment group for $SkuPartNumber"
                MailEnabled        = $false
                SecurityEnabled    = $true
                MailNickname       = $displayName
                IsAssignableToRole = $false
            }
        }

        'ENTRAROLE' {
            $displayNameSplat = @{
                Intent         = $Intent
                RoleName       = $RoleName
                AssignmentType = $AssignmentType
            }
            $displayName = Invoke-MWECommand -Command 'Get-MWEGroupDisplayName' -Splat $displayNameSplat

            $groupSplat = @{
                DisplayName        = $displayName
                Description        = "Entra role assignment group for $RoleName"
                MailEnabled        = $false
                SecurityEnabled    = $true
                MailNickname       = $displayName
                IsAssignableToRole = $true
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($groupSplat.DisplayName, 'Create group')) {
        try {
            $newGroup = Invoke-MWECommand -Command 'New-MgGroup' -Splat $groupSplat
            Write-Information -MessageData "Created new group with Id: $($newGroup.Id)"
            return $newGroup
        }
        catch {
            throw
        }
    }
}
