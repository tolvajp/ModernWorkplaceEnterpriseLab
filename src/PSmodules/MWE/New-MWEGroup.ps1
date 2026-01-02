function New-MWEGroup {
<#
.SYNOPSIS
Creates a Microsoft Entra ID security group according to enforced MWE decisions.

.DESCRIPTION
Creates a Microsoft Entra ID **security group** following the Modern Workplace Enterprise (MWE)
decision model. The function supports two distinct **group intent categories** via parameter sets:

- **LICENSE** – Group-based license assignment groups
- **ENTRAROLE** – Entra ID directory role assignment groups (Active or Eligible via PIM)

The function enforces:
- deterministic, decision-driven group naming
- idempotent creation (duplicate intent results in throw)
- optional group-based license assignment
- optional role activation and PIM role assignment

---

GROUP NAMING MODEL

The group display name is constructed deterministically as:

    <Principal>-<Function>-<Specifier>

Where:
- **Principal**: identity scope  
  - `U` = User  
  - `D` = Device  
  - `X` = Mixed
- **Function**: intent category token  
  - `LICENSE`
  - `ENTRAROLE`
- **Specifier**:
  - LICENSE: SKU part number
  - ENTRAROLE: Role name + assignment type (ACTIVE / ELIGIBLE)

Examples:
- `U-LICENSE-SPE_E5`
- <`U-ENTRAROLE-GlobalAdministrator-ACTIVE`|`U-ENTRAROLE-GlobalAdministrator-ELIGIBLE`>

The resulting displayName is normalized to allow only:
- A–Z, a–z
- 0–9
- underscore (_)
- hyphen (-)

A maximum length of **64 characters** is enforced.

If a group with the same **declared intent** already exists, the function throws.

---

BEHAVIOR

LICENSE parameter set:
- Creates a license assignment group
- When `-Mock` is **not** specified:
  - validates the SKU exists in the tenant
  - assigns the license to the group via group-based licensing
- When `-Mock` **is** specified:
  - creates the group only
  - skips license assignment

ENTRAROLE parameter set:
- Creates an Entra ID role assignment group
- Supports two assignment modes:
  - **Active**   → permanent active role assignment
  - **Eligible** → PIM-eligible role assignment
- Ensures the directory role is activated in the tenant (auto-activates if missing)
- Applies PIM role assignment via Microsoft Graph
- Updates the role management policy expiration rule for activation duration

Supports `-WhatIf` and `-Confirm`.

---

.PARAMETER SkuPartNumber
( LICENSE )
Specifies the license SKU part number used as the specifier in the group name.
In non-mock mode, the SKU must exist in the tenant.

.PARAMETER Mock
( LICENSE )
When specified, skips license assignment.
Used to model license groups for SKUs not purchased in the lab tenant.

.PARAMETER RoleName
( ENTRAROLE )
Display name of the Entra ID directory role
(e.g. "Global Administrator").

.PARAMETER AssignmentType
( ENTRAROLE )
Specifies how the role is assigned to the group.
Valid values:
- Active
- Eligible

.PARAMETER MaximumActivationHours
( ENTRAROLE )
Maximum activation duration (hours) enforced via PIM role management policy.
Valid range: 1–9 hours.
Default: 9

.PARAMETER Force
( ENTRAROLE )
Overrides the requirement for the directory role to already be active.

---

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5'

Creates the group:
    U-LICENSE-SPE_E5
and assigns the SPE_E5 license to the group.

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock

Creates the group without assigning the license.

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5' -WhatIf

Shows what would happen without creating the group or assigning the license.

.EXAMPLE
PS> New-MWEGroup -RoleName 'Global Administrator' -AssignmentType Eligible

Creates:
    U-ENTRAROLE-GlobalAdministrator-ELIGIBLE
and assigns the role as PIM-eligible.

.EXAMPLE
PS> New-MWEGroup -RoleName 'Global Administrator' -AssignmentType Active -MaximumActivationHours 5

Creates:
    U-ENTRAROLE-GlobalAdministrator-ACTIVE
and assigns the role as an active role assignment
with a 5-hour expiration.

---

.OUTPUTS
Microsoft.Graph.PowerShell.Models.IMicrosoftGraphGroup

Returns the created group object.
Returns `$null` when `-WhatIf` is used.

---

.REQUIRED SCOPES
Delegated Microsoft Graph permissions (admin consent required):

- Group.ReadWrite.All
- LicenseAssignment.ReadWrite.All
- Directory.ReadWrite.All
- RoleManagement.ReadWrite.Directory

---

.NOTES
This function is part of the MWE PowerShell module and is intended for lab automation.

Architectural note:
This function enforces **group and role assignment decisions**.
Changes to behavior may require updates to:
- decision records
- runbooks
- documentation

In real enterprise environments, such changes should follow
formal change management and approval processes.
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
        
        [Parameter(Mandatory,ParameterSetName = 'ENTRAROLE')]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType,

        [Parameter(ParameterSetName = 'ENTRAROLE')]
        [Int32]$MaximumActivationHours = 9
    )

    #Parameter validation is handled here since sometimes it needs several parameters.
    switch ($PSCmdlet.ParameterSetName) {

        'LICENSE' {
            if ((-not $Mock) -and ($SkuPartNumber -notin  (Get-MgSubscribedSku).SkuPartNumber)) {
            throw "No such License bought for the company: $SkuPartNumber"
            }
        }  
        
        'ENTRAROLE' {
            $templateRoles=Get-MgDirectoryRoleTemplate -All
            $activatedRoles=Get-MgDirectoryRole -All
            if ($RoleName -notin $templateRoles.displayName) {
                throw "No such Entra directory role template: $RoleName"
            }
            if ((-not $Force) -and ($RoleName -notin $activatedRoles.displayName)) {
                throw "No such Active Entra directory role: $RoleName Consider using the -Force parameter to activate it."
            }
            if ($MaximumActivationHours -lt 1 -or $MaximumActivationHours -gt 9) {
                throw "MaximumActivationHours must be between 1 and 9."
        }
    }
}

    #Group creation input creation
    $newGroup = $null
    $groupSplat = switch ($PSCmdlet.ParameterSetName) {

        'LICENSE' {
            $prefix = 'U'
            $principal = $PSCmdlet.ParameterSetName
            $normalizedDisplayName = "$prefix-$principal-$SkuPartNumber" -replace '[^a-zA-Z0-9_-]', ''

            if ($normalizedDisplayName.Length -gt 64) {
                throw "Normalized group name '$normalizedDisplayName' is longer than 64 characters. Shorten the input."
            }
            @{
                DisplayName     = $normalizedDisplayName
                Description     = "License assignment group for $SkuPartNumber"
                MailEnabled     = $false
                SecurityEnabled = $true
                MailNickname    = $normalizedDisplayName
            }  
        }

        'ENTRAROLE' {
            $prefix = 'U'
            $principal = $PSCmdlet.ParameterSetName
            $normalizedDisplayName = "$prefix-$principal-$RoleName-$($AssignmentType.ToUpper())" -replace '[^a-zA-Z0-9_-]', ''

            if ($normalizedDisplayName.Length -gt 64) {
                throw "Normalized group name '$normalizedDisplayName' is longer than 64 characters. Shorten the input."
            }
            @{
                DisplayName     = $normalizedDisplayName
                Description     = "Entra role assignment group for $RoleName"
                MailEnabled     = $false
                SecurityEnabled = $true
                MailNickname    = $normalizedDisplayName
                IsAssignableToRole = $true
            }

        }
    }

    switch ($PSCmdlet.ParameterSetName) {

        'LICENSE' {
        $existingGroup=Get-MgGroup -Filter "displayName eq '$($groupSplat.DisplayName)'" -Top 1
        }
    
        
        'ENTRAROLE' {
            $eligibleGroupName="$prefix-$principal-$RoleName-ELIGIBLE" -replace '[^a-zA-Z0-9_-]', ''
            $activeGroupName="$prefix-$principal-$RoleName-ACTIVE" -replace '[^a-zA-Z0-9_-]', ''
            $existingGroup=Get-MgGroup -Filter "displayName eq '$eligibleGroupName'" -Top 1
            if ($null -eq $existingGroup) {
                $existingGroup=Get-MgGroup -Filter "displayName eq '$activeGroupName'" -Top 1
            }   
        }
    }   

    #Group creation
    
    if ($existingGroup) {
        throw "Group '$($existingGroup.DisplayName)' already exists with Id: $($existingGroup.Id). Use that one."
    }
    else {
        if ($PSCmdlet.ShouldProcess($groupSplat.DisplayName, 'Create group')) {
            try {
                $newGroup = New-MgGroup @groupSplat
                Write-Verbose "Created new group with Id: $($newGroup.Id)"
            }
            catch {
                throw "Failed to create group '$($groupSplat.DisplayName)': $_"
            }
        }
    }

    #license assignment if needed
    if ($PSCmdlet.ParameterSetName -eq 'LICENSE' -and (-not $mock)) {
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
        #Parameter validation already throw if it should not be acivated. if we are here, we should activate.. Now ensure it's activated.
        if ($RoleName -notin $activatedRoles.DisplayName) {
            $template = $templateRoles | Where-Object DisplayName -eq $RoleName | Select-Object -First 1
            if (-not $template) { throw "No such Entra directory role template: $RoleName" }
            New-MgDirectoryRole -RoleTemplateId $template.Id
            }
        
        $roleDef = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$RoleName'" | Select-Object -First 1
        if (-not $roleDef) { throw "No such role definition found for role name: $RoleName" }

        if ($AssignmentType -eq 'Active') {
            $whatifMessage = "Assign role $RoleName as $AssignmentType to group $($newGroup.DisplayName)"
            $policyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$($roleDef.Id)'" | Select-Object -First 1
            if (-not $policyAssignment) { throw "No role management policy assignment found for roleDefinitionId '$($roleDef.Id)' (scope '/')." }
            $rule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId | Where-Object Id -eq "Expiration_EndUser_Assignment" | Select-Object -First 1
            if (-not $rule) { throw "Role management policy rule 'Expiration_EndUser_Assignment' not found for PolicyId '$($policyAssignment.PolicyId)'." }

            if ($PSCmdlet.ShouldProcess($whatifMessage)) {
                Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId -UnifiedRoleManagementPolicyRuleId $rule.Id -BodyParameter @{
                    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                    isExpirationRequired = $true
                    maximumDuration = "PT$($MaximumActivationHours)H"
                }
                $activeAssignSplat=@{
                    action = "adminAssign"
                    principalId = $newGroup.Id
                    roleDefinitionId = $roleDef.Id
                    directoryScopeId = "/"
                    justification="LAB justification. In prod I would ask a ticket number with a parameeeter to fill this."
                    scheduleInfo = @{
                        startDateTime = (Get-Date).ToString("o")
                        expiration = @{
                            type = "afterDuration"
                            duration = "PT$($MaximumActivationHours)H"
                        }
                    }
                }

                # Retry required due to Entra ID / PIM eventual consistency: newly created role-assignable groups may not be immediately resolvable as principals
                $retryUntil = (Get-Date).AddMinutes(5)
                while ($true) {
                    try {
                        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $activeAssignSplat
                        break
                    } catch {
                        if (($_.Exception.Message -match 'SubjectNotFound') -or ($_.FullyQualifiedErrorId -match 'SubjectNotFound')) {
                            if ((Get-Date) -ge $retryUntil) { throw }
                            Start-Sleep -Seconds 10
                            continue
                        }
                        throw
                    }
                }
            }
        } elseif ($AssignmentType -eq 'Eligible') {
            $whatifMessage = "Assign role $RoleName as $AssignmentType to group $($newGroup.DisplayName) with max activation hours: $MaximumActivationHours"
            $policyAssignment = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$($roleDef.Id)'" | Select-Object -First 1
            if (-not $policyAssignment) { throw "No role management policy assignment found for roleDefinitionId '$($roleDef.Id)' (scope '/')." }
            $rule = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId | Where-Object Id -eq "Expiration_EndUser_Assignment"
            if (-not $rule) { throw "Role management policy rule 'Expiration_EndUser_Assignment' not found for PolicyId '$($policyAssignment.PolicyId)'." }

            if ($PSCmdlet.ShouldProcess($whatifMessage)) {
                Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyAssignment.PolicyId -UnifiedRoleManagementPolicyRuleId $rule.Id -BodyParameter @{
                    "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                    isExpirationRequired = $true
                    maximumDuration = "PT$($MaximumActivationHours)H"
                }
                $eligibleAssignSplat=@{
                    action = "adminAssign"
                    principalId = $newGroup.Id
                    roleDefinitionId = $roleDef.Id
                    directoryScopeId = "/"
                    justification="LAB justification. In prod I would ask a ticket number with a parameeeter to fill this."
                    scheduleInfo = @{
                        startDateTime = (Get-Date).ToString("o")
                        expiration = @{
                            type = "noExpiration"
                        }
                    }
                }

                # Retry required due to Entra ID / PIM eventual consistency: newly created role-assignable groups may not be immediately resolvable as principals
                $retryUntil = (Get-Date).AddMinutes(5)
                while ($true) {
                    try {
                        New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $eligibleAssignSplat
                        break
                    } catch {
                        if (($_.Exception.Message -match 'SubjectNotFound') -or ($_.FullyQualifiedErrorId -match 'SubjectNotFound')) {
                            if ((Get-Date) -ge $retryUntil) { throw }
                            Start-Sleep -Seconds 10
                            continue
                        }
                        throw
                    }
                }
            }
        }
    }
return $newGroup
}
