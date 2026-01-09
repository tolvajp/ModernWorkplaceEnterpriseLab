function Assert-MWEExistingGroup {
<#
.SYNOPSIS
Ensures that no conflicting Entra ID group already exists.

.DESCRIPTION
Validates that no Entra ID group exists for the given naming intent.
If a matching group is found, the function throws a terminating error.

This function:
- Is intended for internal module use
- Performs validation only (no state change)
- Does not return output
- Throws on invalid input or conflicting state

Supported intents:
- LICENSE    : Validates license group non-existence
- ENTRAROLE  : Validates role (Eligible / Active) group non-existence

.PARAMETER Intent
Specifies the group intent being validated.
Supported values: LICENSE, ENTRAROLE.

.PARAMETER SkuPartNumber
License SkuPartNumber used for LICENSE group validation.
Required when Intent is LICENSE.

.PARAMETER RoleName
Role display name used for ENTRAROLE group validation.
Required when Intent is ENTRAROLE.

.NOTES
- This is an assertion helper and must not perform Graph mutations.
- Intended to be called by public orchestration functions prior to creation.
- Throws terminating errors by design.

.REQUIRED GRAPH SCOPES
Delegated or Application permissions:
- Group.Read.All

.LINK
https://learn.microsoft.com/graph/api/group-list
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$Intent,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [string]$RoleName
    )
    $ErrorActionPreference = 'Stop'
    # --- Parameter guards / contract validation ---
    switch ($Intent) {
        'LICENSE' {
            if (-not $SkuPartNumber) {throw "SkuPartNumber is required when Intent is 'LICENSE'."}
        }

        'ENTRAROLE' {
            if (-not $RoleName) {throw "RoleName is required when Intent is 'ENTRAROLE'."}
        }
    }

    # --- Data lookup / normalization ---
    switch ($Intent) {
        'LICENSE' {
            $groupDisplayNameSplat= @{
                Intent        = $Intent
                SkuPartNumber = $SkuPartNumber
            }
            $name = Invoke-MWECommand -Command 'Get-MWEGroupDisplayName' -Splat $groupDisplayNameSplat
            $existingGroup = Get-MgGroup -Filter "displayName eq '$name'" -Top 1
        }

        'ENTRAROLE' {
            $eligibleNameSplat = @{
                Intent         = $Intent
                RoleName       = $RoleName
                AssignmentType = 'Eligible'
            }
            $activeNameSplat   = @{
                Intent         = $Intent
                RoleName       = $RoleName
                AssignmentType = 'Active'
            }
            $eligibleName = Invoke-MWECommand -Command 'Get-MWEGroupDisplayName' -Splat $eligibleNameSplat
            $activeName   = Invoke-MWECommand -Command 'Get-MWEGroupDisplayName' -Splat $activeNameSplat

            $filter = "displayName eq '$eligibleName' or displayName eq '$activeName'"
            $existingGroupsplat= @{
                Filter = $filter
                Top    = 1
            }
            $existingGroup = Invoke-MWECommand -Command 'Get-MgGroup' -Splat $existingGroupsplat
        }
    }

    # --- Assertion ---
    if ($existingGroup) {
        throw "Group '$($existingGroup.DisplayName)' already exists with Id: $($existingGroup.Id). Use that one."
    }
}