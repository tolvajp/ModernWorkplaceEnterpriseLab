# Private helper functions are dot-sourced so this script remains runnable standalone (tests dot-source it).
# When imported as a module, MWE.psm1 also dot-sources these helpers.

$privateFunctions = @(
    'Assert-MWEGroupParameters.ps1',
    'ConvertTo-NWEStandardizedName.ps1',
    'Get-MWEExistingGroup.ps1',
    'Invoke-NWEWithLazyProperty.ps1',
    'New-MWEGroupSplat.ps1'
)

foreach ($privateFunction in $privateFunctions) {
    $helperPath = Join-Path -Path $PSScriptRoot -ChildPath "Private\$privateFunction"
    if (-not (Test-Path -Path $helperPath)) { throw "Private helper not found: $helperPath" }
    . $helperPath
}

function New-MWEGroup {
<#
.SYNOPSIS
Creates a Microsoft Entra ID security group according to enforced MWE decisions.

.DESCRIPTION
Creates a Microsoft Entra ID **security group** following the Modern Workplace Enterprise (MWE)
decision model. The function supports two distinct **group intent categories** via parameter sets:

- **LICENSE** – Group-based license assignment groups
- **ENTRAROLE** – Entra ID directory role assignment groups (Active or Eligible via PIM)

Supports `-WhatIf` and `-Confirm`.
#>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'LICENSE')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'LICENSE')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber,

        [Parameter(ParameterSetName = 'LICENSE')]
        [switch]$Mock,

        [Parameter(Mandatory, ParameterSetName = 'ENTRAROLE')]
        [ValidateNotNullOrEmpty()]
        [string]$RoleName,

        [Parameter(ParameterSetName = 'ENTRAROLE')]
        [switch]$Force,

        [Parameter(Mandatory, ParameterSetName = 'ENTRAROLE')]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType,

        [Parameter(ParameterSetName = 'ENTRAROLE')]
        [Int32]$MaximumActivationHours = 9
    )

    $parameterContext = Assert-MWEGroupParameters -ParameterSetName $PSCmdlet.ParameterSetName -SkuPartNumber $SkuPartNumber -Mock:$Mock -RoleName $RoleName -Force:$Force -MaximumActivationHours $MaximumActivationHours
    $groupSplat = New-MWEGroupSplat -ParameterSetName $PSCmdlet.ParameterSetName -SkuPartNumber $SkuPartNumber -RoleName $RoleName -AssignmentType $AssignmentType

    $existingGroup = Get-MWEExistingGroup -ParameterSetName $PSCmdlet.ParameterSetName -SkuPartNumber $SkuPartNumber -RoleName $RoleName

    if ($existingGroup) {
        throw "Group '$($existingGroup.DisplayName)' already exists with Id: $($existingGroup.Id). Use that one."
    }

    $newGroup = $null

    if ($PSCmdlet.ShouldProcess($groupSplat.DisplayName, 'Create group')) {
        try {
            $newGroup = New-MgGroup @groupSplat
            Write-Verbose "Created new group with Id: $($newGroup.Id)"
        }
        catch {
            throw "Failed to create group '$($groupSplat.DisplayName)': $_"
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'LICENSE' -and (-not $Mock)) {
        if ($PSCmdlet.ShouldProcess("Assign license $SkuPartNumber to group $($groupSplat.DisplayName)")) {
            $licenseSplat = @{
                AddLicenses    = @(
                    @{
                        SkuId = (Get-MgSubscribedSku | Where-Object SkuPartNumber -eq $SkuPartNumber).SkuId
                    }
                )
                RemoveLicenses = @()
                GroupId        = $newGroup.Id
            }

            try {
                Set-MgGroupLicense @licenseSplat
                Write-Verbose "Assigned license $SkuPartNumber to group $($newGroup.DisplayName)"
            }
            catch {
                throw "Failed to assign license '$SkuPartNumber' to group '$($newGroup.DisplayName)': $_"
            }
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'ENTRAROLE') {

        # -Force handling: this is where tenant-level directory role instantiation (template -> role) happens when missing.
        if (($RoleName -notin $parameterContext.ActivatedRoles.DisplayName) -and $Force) {
            $template = $parameterContext.TemplateRoles | Where-Object DisplayName -eq $RoleName | Select-Object -First 1
            if (-not $template) { throw "No such Entra directory role template: $RoleName" }
            New-MgDirectoryRole -RoleTemplateId $template.Id
        }

        $roleDef = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$RoleName'" | Select-Object -First 1
        if (-not $roleDef) { throw "No such role definition found for role name: $RoleName" }

        $policyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$($roleDef.Id)'" | Select-Object -First 1
        if (-not $policyAssignment) { throw "No role management policy assignment found for roleDefinitionId '$($roleDef.Id)' (scope '/')." }

        $rule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId | Where-Object Id -eq 'Expiration_EndUser_Assignment' | Select-Object -First 1
        if (-not $rule) { throw "Role management policy rule 'Expiration_EndUser_Assignment' not found for PolicyId '$($policyAssignment.PolicyId)'." }

        $whatIfMessage = if ($AssignmentType -eq 'Active') {
            "Assign role $RoleName as $AssignmentType to group $($newGroup.DisplayName)"
        } else {
            "Assign role $RoleName as $AssignmentType to group $($newGroup.DisplayName) with max activation hours: $MaximumActivationHours"
        }

        if ($PSCmdlet.ShouldProcess($whatIfMessage)) {

            Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId -UnifiedRoleManagementPolicyRuleId $rule.Id -BodyParameter @{
                '@odata.type'        = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
                isExpirationRequired = $true
                maximumDuration      = "PT$($MaximumActivationHours)H"
            }

            if ($AssignmentType -eq 'Active') {
                $activeAssignSplat = @{
                    action           = 'adminAssign'
                    principalId      = $newGroup.Id
                    roleDefinitionId = $roleDef.Id
                    directoryScopeId = '/'
                    justification    = 'LAB justification. In prod I would ask a ticket number with a parameeeter to fill this.'
                    scheduleInfo     = @{
                        startDateTime = (Get-Date).ToString('o')
                        expiration    = @{
                            type     = 'afterDuration'
                            duration = "PT$($MaximumActivationHours)H"
                        }
                    }
                }

                Invoke-NWEWithLazyProperty -ErrorId 'SubjectNotFound' -ScriptBlock {
                    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $activeAssignSplat
                } | Out-Null
            }

            if ($AssignmentType -eq 'Eligible') {
                $eligibleAssignSplat = @{
                    action           = 'adminAssign'
                    principalId      = $newGroup.Id
                    roleDefinitionId = $roleDef.Id
                    directoryScopeId = '/'
                    justification    = 'LAB justification. In prod I would ask a ticket number with a parameeeter to fill this.'
                    scheduleInfo     = @{
                        startDateTime = (Get-Date).ToString('o')
                        expiration    = @{
                            type = 'noExpiration'
                        }
                    }
                }

                Invoke-NWEWithLazyProperty -ErrorId 'SubjectNotFound' -ScriptBlock {
                    New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $eligibleAssignSplat
                } | Out-Null
            }
        }
    }

    return $newGroup
}
