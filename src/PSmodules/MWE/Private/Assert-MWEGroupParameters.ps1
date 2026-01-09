function Assert-MWEGroupParameters {
<#
.SYNOPSIS
Validates New-MWEGroup parameters and intent-specific prerequisites.

.DESCRIPTION
Validates the parameter contract and intent-specific prerequisites for New-MWEGroup.
This function performs no Microsoft Graph I/O. All tenant-derived data must be
retrieved by the caller and passed in explicitly.

This function:
- Is intended for internal module use
- Performs validation only (no state change)
- Does not return output
- Throws terminating errors on invalid input or inconsistent state

Supported intents:
- LICENSE
- ENTRAROLE

.PARAMETER Intent
Specifies the group intent being validated.
Supported values: LICENSE, ENTRAROLE.

.PARAMETER SkuPartNumber
License SKU part number.
Required when Intent is LICENSE and -Mock is not specified.

.PARAMETER Mock
When specified, skips tenant SKU validation.

.PARAMETER AssignmentType
Role assignment type.
Valid values: Active, Eligible.
Used only when Intent is ENTRAROLE.

.PARAMETER RoleName
Entra ID directory role display name.
Required when Intent is ENTRAROLE.

.PARAMETER Force
Overrides the requirement for the directory role to already be activated.

.PARAMETER MaximumActivationHours
Maximum activation duration in hours.
Validated when AssignmentType is Eligible.
Valid range: 1–9.

.PARAMETER AvailableSkuPartNumbers
List of SKU part numbers available in the tenant.
Must be provided by the caller for LICENSE validation.

.PARAMETER RoleDefinitionDisplayNames
List of available directory role template display names.
Must be provided by the caller for ENTRAROLE validation.

.PARAMETER ActivatedRoleDisplayNames
List of currently activated directory role display names.
Must be provided by the caller for ENTRAROLE validation.

.PARAMETER ExpirationDate
Optional schedule expiration date/time for ENTRAROLE assignments.
When provided:
- Must not be in the past (relative to the current time at validation)
- Applies to the role assignment/eligibility schedule request (not activation)

If not provided, the schedule is created with no expiration.

.NOTES
- This is an assertion helper and must not perform Graph I/O.
- The caller is responsible for retrieving tenant state.
- Throws terminating errors by design.

.REQUIRED GRAPH SCOPES
None (no Graph calls performed).

.LINK
https://learn.microsoft.com/graph/
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$Intent,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [switch]$Mock,

        [Parameter()]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType,

        [Parameter()]
        [string]$RoleName,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [int]$MaximumActivationHours,

        [Parameter()]
        [string[]]$AvailableSkuPartNumbers,

        [Parameter()]
        [string[]]$RoleDefinitionDisplayNames,

        [Parameter()]
        [string[]]$DirectoryRoleDisplayNames,

        [Parameter()]
        [datetime]$ExpirationDate
    )
    $ErrorActionPreference = 'Stop'
    switch ($Intent) {
        'LICENSE' {
            if ([string]::IsNullOrWhiteSpace($SkuPartNumber)) { throw "SkuPartNumber is empty or null." }
            if ((-not $Mock) -and (-not $AvailableSkuPartNumbers)) {
                throw "LICENSE parameter validation requires -AvailableSkuPartNumbers to be provided by New-MWEGroup."
            }

            if ((-not $Mock) -and ($SkuPartNumber -notin $AvailableSkuPartNumbers)) {
                throw "No such License bought for the company: $SkuPartNumber"
            }
        }

        'ENTRAROLE' {
            if ([string]::IsNullOrWhiteSpace($RoleName)) { throw "RoleName is empty or null." }
            if (-not $RoleDefinitionDisplayNames -or -not $DirectoryRoleDisplayNames) {
                throw "ENTRAROLE parameter validation requires -RoleDefinitionDisplayNames and -ActivatedRoleDisplayNames to be provided by New-MWEGroup."
            }

            if ($RoleName -notin $RoleDefinitionDisplayNames) {
                throw "No such Entra directory role definition: $RoleName"
            }

            if ((-not $Force) -and ($RoleName -notin $DirectoryRoleDisplayNames)) {
                throw "No such Active Entra directory role: $RoleName Consider using the -Force parameter to activate it."
            }

            if (($AssignmentType -eq 'Eligible') -and (-not $MaximumActivationHours -or $MaximumActivationHours -lt 1 -or $MaximumActivationHours -gt 9)) {
                throw "If Assignement type is Eligible, Maximum activation hours should be between 1 and 9."
            }

            if (($AssignmentType -eq 'Active') -and $PSBoundParameters.ContainsKey('MaximumActivationHours')) {
                throw "Active PIM assignemeent doesn't need MaximumActivationHours to be set."
            }

            if ($ExpirationDate -and ($ExpirationDate -lt (Get-Date))) {
                throw "ExpirationDate cannot be in the past."
            }
        }
        # Unsupported Intent values are rejected by the ValidateSet on this function parameter.
    }
}
