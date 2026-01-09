function Set-MWEGroupEntraRoleAssignment {
    <#
.SYNOPSIS
Assigns an Entra ID directory role to a group and configures PIM activation limits when applicable.

.DESCRIPTION
Assigns an Entra ID directory role to a security group using Microsoft Graph role
management APIs.

Depending on the provided parameters, this function:
- Assigns the role to the group as Active or Eligible
- Activates the directory role in the tenant when required (-Force)
- Configures the maximum PIM activation duration for Eligible assignments

The function:
- Validates role existence using provided role definition and directory role data
- Performs state-changing operations via Microsoft Graph
- Handles Graph eventual consistency using retry logic
- Emits informational log entries when state changes occur
- Supports WhatIf / Confirm semantics for all state-changing operations

Authentication and required Microsoft Graph permissions are explicit preconditions.

.PARAMETER GroupId
The object ID of the Entra ID group to which the role will be assigned.

.PARAMETER RoleName
The display name of the Entra ID directory role to assign
(for example: "Global Administrator").

.PARAMETER Force
When specified, activates the directory role in the tenant if it is not currently active
before attempting the assignment.

.PARAMETER AssignmentType
Specifies how the role is assigned to the group.

Supported values:
- Active   : Assigns the role as permanently active
- Eligible : Assigns the role as PIM-eligible

.PARAMETER MaximumActivationHours
Maximum number of hours a PIM-eligible role can be activated for.

This parameter:
- Is REQUIRED when AssignmentType is 'Eligible'
- Is NOT allowed when AssignmentType is 'Active'

.PARAMETER RoleDefinitions
A collection of Entra ID role definitions retrieved from Microsoft Graph.
Used for validation and role definition ID resolution.

.PARAMETER DirectoryRoles
A collection of currently active Entra ID directory roles retrieved from Microsoft Graph.
Used to determine whether role activation is required.

.OUTPUTS
None.

This function performs state-changing operations and does not return output objects.
Operational results are communicated via informational log messages.

.EXAMPLE
Set-MWEGroupEntraRoleAssignment `
    -GroupId '11111111-1111-1111-1111-111111111111' `
    -RoleName 'Global Administrator' `
    -AssignmentType Active `
    -RoleDefinitions $roleDefinitions `
    -DirectoryRoles $directoryRoles

Assigns the Global Administrator role to the group as an active role assignment.

.EXAMPLE
Set-MWEGroupEntraRoleAssignment `
    -GroupId '22222222-2222-2222-2222-222222222222' `
    -RoleName 'Security Reader' `
    -AssignmentType Eligible `
    -MaximumActivationHours 8 `
    -RoleDefinitions $roleDefinitions `
    -DirectoryRoles $directoryRoles

Assigns the Security Reader role to the group as a PIM-eligible assignment
and configures a maximum activation duration of 8 hours.

.EXAMPLE
Set-MWEGroupEntraRoleAssignment `
    -GroupId '33333333-3333-3333-3333-333333333333' `
    -RoleName 'Privileged Role Administrator' `
    -AssignmentType Eligible `
    -MaximumActivationHours 4 `
    -Force `
    -RoleDefinitions $roleDefinitions `
    -DirectoryRoles $directoryRoles `
    -WhatIf

Shows what would happen if the Privileged Role Administrator role were activated
(if required), assigned as an eligible role, and configured with a 4-hour
maximum activation duration.

.NOTES
- This function performs state-changing operations in Entra ID.
- Authentication and authorization are explicit preconditions.
- Microsoft Graph errors are not wrapped or altered.
- Eventual consistency is handled using retry logic.
- Intended for internal use within the MWE automation framework.

.REQUIRED GRAPH SCOPES
Delegated or Application permissions:
- RoleManagement.ReadWrite.Directory
- Directory.ReadWrite.All
- Group.ReadWrite.All

.LINK
https://learn.microsoft.com/graph/api/resources/rolemanagement

.LINK
https://learn.microsoft.com/graph/api/rbacapplication-post-roleeligibilityschedulerequests

.LINK
https://learn.microsoft.com/entra/id-governance/privileged-identity-management
#>


[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [string]$GroupId,

    [Parameter(Mandatory)]
    [string]$RoleName,

    [Parameter()]
    [switch]$Force,

    [Parameter(Mandatory)]
    [ValidateSet('Active', 'Eligible')]
    [string]$AssignmentType,

    [Parameter()]
    [int]$MaximumActivationHours,

    [Parameter(Mandatory)]
    [object[]]$RoleDefinitions,

    [Parameter(Mandatory)]
    [object[]]$DirectoryRoles
)
$ErrorActionPreference = 'Stop'
# Basic parameter validation
switch ($AssignmentType) {
    'Active' {
        if ($PSBoundParameters.ContainsKey('MaximumActivationHours')) {
            throw "MaximumActivationHours is not applicable for 'Active' assignments."
        }
    }
    'Eligible' {
        if (-not $PSBoundParameters.ContainsKey('MaximumActivationHours')) {
            throw "MaximumActivationHours is required for 'Eligible' assignments."
        }
    }
}

if ($RoleName -notin $RoleDefinitions.DisplayName) {
    throw "No such Entra directory role definition: $RoleName"
}

if ($RoleName -notin $DirectoryRoles.DisplayName) {
    if (-not $Force) {
        throw "No such Active Entra directory role: $RoleName Consider using the -Force parameter to activate it."
    }

    if ($PSCmdlet.ShouldProcess($RoleName, 'Activate directory role')) {
        $roleTemplateSplat = @{
            Filter = "displayName eq '$RoleName'"
        }

        $roleTemplate = Invoke-MWECommand -Command 'Get-MgDirectoryRoleTemplate' -Splat $roleTemplateSplat |
        Select-Object -First 1

        if (-not $roleTemplate) {
            throw "DirectoryRoleTemplate not found for role name: '$RoleName'."
        }

        $enableRoleSplat = @{
            DirectoryRoleTemplateId = $roleTemplate.Id
        }

        Invoke-MWECommand -Command 'Enable-MgDirectoryRole' -Splat $enableRoleSplat

        Write-Information -MessageData "Activated directory role '$RoleName' (DirectoryRoleTemplateId: $($roleTemplate.Id))."
    }
}

$roleDefinition = $RoleDefinitions |
Where-Object { $_.DisplayName -eq $RoleName } |
Select-Object -First 1

if (-not $roleDefinition) {
    throw "Role definition not found in RoleDefinitions for RoleName '$RoleName'."
}

$roleDefinitionId = $roleDefinition.Id
$nowIso = (Get-Date).ToString('o')

$scheduleInfo = @{
    startDateTime = $nowIso
    expiration    = @{ type = 'NoExpiration' }
}

$requestBody = @{
    action           = 'adminAssign'
    principalId      = $GroupId
    roleDefinitionId = $roleDefinitionId
    directoryScopeId = '/'
    justification    = 'MWE automated role assignment In prod it would bee ticket number or such.'
    scheduleInfo     = $scheduleInfo
}

switch ($AssignmentType) {
    'Eligible' {
        if ($PSCmdlet.ShouldProcess($GroupId, "Assign ELIGIBLE role '$RoleName' (roleDefinitionId: $roleDefinitionId)")) {
            Invoke-NWEWithLazyObject -ScriptBlock {
                Invoke-MWECommand -Command 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest' -Splat @{
                    BodyParameter = $requestBody
                } | Out-Null
            } -ErrorMessagePatterns @('SubjectNotFound') -TimeoutSeconds 300 -SleepSeconds 10

            Write-Information -MessageData "Assigned ELIGIBLE role '$RoleName' to group '$GroupId' (roleDefinitionId: $roleDefinitionId)."
        }
    }

    'Active' {
        if ($PSCmdlet.ShouldProcess($GroupId, "Assign ACTIVE role '$RoleName' (roleDefinitionId: $roleDefinitionId)")) {
            Invoke-NWEWithLazyObject -ScriptBlock {
                Invoke-MWECommand -Command 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest' -Splat @{
                    BodyParameter = $requestBody
                } | Out-Null
            } -ErrorMessagePatterns @('SubjectNotFound') -TimeoutSeconds 300 -SleepSeconds 10

            Write-Information -MessageData "Assigned ACTIVE role '$RoleName' to group '$GroupId' (roleDefinitionId: $roleDefinitionId)."
        }
    }
}

if ($AssignmentType -eq 'Eligible') {
    $pimSplat = @{
        RoleDefinitionId       = $roleDefinitionId
        MaximumActivationHours = $MaximumActivationHours
    }

    Invoke-MWECommand -Command 'Set-MWEPimEligibilityMaximumActivationHours' -Splat $pimSplat

    Write-Information -MessageData "Set PIM maximum activation hours to $MaximumActivationHours for roleDefinitionId: $roleDefinitionId."
}
}
