function Set-MWEPIMEligibilityMaximumActivationHours {
<#
.SYNOPSIS
Sets the maximum activation duration for an Eligible Entra ID role (PIM).

.DESCRIPTION
Implements a deterministic helper function that updates the Entra ID
Privileged Identity Management (PIM) policy for an Eligible role assignment
by enforcing a maximum activation duration.

This function:
- Is intended for internal module use
- Performs a single, well-defined state change
- Does not create or assign role memberships
- Does not perform orchestration logic
- Supports WhatIf / Confirm semantics
- Throws terminating errors on invalid input or Graph failures

.PARAMETER RoleDefinitionId
The Entra ID role definition identifier used to resolve the associated
role management policy.

.PARAMETER MaximumActivationHours
Maximum number of hours an Eligible role activation may remain active.

.OUTPUTS
None.

.EXAMPLE
Set-MWEPimEligibilityMaximumActivationHours -RoleDefinitionId '62e90394-69f5-4237-9190-012177145e10' -MaximumActivationHours 1

.EXAMPLE
Set-MWEPimEligibilityMaximumActivationHours -RoleDefinitionId '62e90394-69f5-4237-9190-012177145e10' -MaximumActivationHours 2 -WhatIf

.NOTES
- Internal helper function
- Designed for reuse by higher-level orchestration functions
- Uses Microsoft Graph beta policy endpoints explicitly

.REQUIRED GRAPH SCOPES
Application or Delegated permissions:
- RoleManagementPolicy.ReadWrite.Directory

.LINK
https://learn.microsoft.com/graph/api/resources/rolemanagementpolicy

.LINK
https://learn.microsoft.com/entra/id-governance/privileged-identity-management/
#>


    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RoleDefinitionId,

        [Parameter(Mandatory)]
        [ValidateRange(1, 9)]
        [int]$MaximumActivationHours
    )
    $ErrorActionPreference = 'Stop'
    $durationIso = "PT$MaximumActivationHours" + "H"


    # Internal retry knobs
    $timeoutSeconds = 300
    $sleepSeconds = 2

    $policyAssignmentUrl = "https://graph.microsoft.com/beta/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$RoleDefinitionId'"

    $policyAssignmentGetSplat = @{
        Method      = 'GET'
        Uri         = $policyAssignmentUrl
        ErrorAction = 'Stop'
    }

    $lazyGetSplat = @{
        ScriptBlock          = { Invoke-MgGraphRequest @policyAssignmentGetSplat }
        ErrorMessagePatterns = @('NotFound', 'ResourceNotFound', 'temporarily unavailable')
        TimeoutSeconds       = $timeoutSeconds
        SleepSeconds         = $sleepSeconds
    }

    $policyAssignment = Invoke-NWEWithLazyObject @lazyGetSplat

    $policyId = $policyAssignment.value | Select-Object -First 1 -ExpandProperty policyId
    if (-not $policyId) { throw "Role management policy assignment not found for roleDefinitionId '$RoleDefinitionId'." }

    $rulesUrl = "https://graph.microsoft.com/beta/policies/roleManagementPolicies/$policyId/rules"

    $policyRulesGetSplat = @{
        Method      = 'GET'
        Uri         = $rulesUrl
        ErrorAction = 'Stop'
    }

    $policyRules = Invoke-MWECommand -Command 'Invoke-MgGraphRequest' -Splat $policyRulesGetSplat

    $expirationCandidates = @($policyRules.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule' })
    if ($expirationCandidates.Count -eq 0) {
        throw "No unifiedRoleManagementPolicyExpirationRule found for policyId '$policyId' (roleDefinitionId '$RoleDefinitionId')."
    }

    $expirationRule =
    ($expirationCandidates | Where-Object { $_.target.caller -eq 'EndUser' -and $_.target.level -eq 'Eligible' } | Select-Object -First 1)

    if (-not $expirationRule) {
        $expirationRule =
        ($expirationCandidates | Where-Object { $_.target.caller -eq 'EndUser' } | Select-Object -First 1)
    }

    if (-not $expirationRule) { $expirationRule = $expirationCandidates | Select-Object -First 1 }

    if (-not $expirationRule.id) {
        throw "Expiration policy rule not found (missing id) for policyId '$policyId' (roleDefinitionId '$RoleDefinitionId')."
    }

    $patchUrl = "https://graph.microsoft.com/beta/policies/roleManagementPolicies/$policyId/rules/$($expirationRule.id)"

    $patchBody = @{
        '@odata.type'        = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
        isExpirationRequired = $true
        maximumDuration      = $durationIso
    }

    $policyRulePatchSplat = @{
        Method      = 'PATCH'
        Uri         = $patchUrl
        Body        = $patchBody
        ErrorAction = 'Stop'
    }

    if ($PSCmdlet.ShouldProcess($RoleDefinitionId, "Set PIM eligible maximum activation duration to $MaximumActivationHours hour(s)")) {
        Invoke-MWECommand -Command 'Invoke-MgGraphRequest' -Splat $policyRulePatchSplat | Out-Null
        Write-Information -MessageData "Set PIM eligible maximum activation duration to $MaximumActivationHours hour(s) for roleDefinitionId '$RoleDefinitionId'."
    }
}
