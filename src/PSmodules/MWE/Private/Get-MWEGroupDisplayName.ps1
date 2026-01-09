function Get-MWEGroupDisplayName {
<#
.SYNOPSIS
Builds the deterministic displayName for an MWE-managed Entra ID group.

.DESCRIPTION
Builds a deterministic Entra ID group displayName according to the
Modern Workplace Enterprise (MWE) naming model.

The generated displayName:
- Is derived solely from the declared intent and parameters
- Is normalized to allow only A–Z, a–z, 0–9, underscore (_) and hyphen (-)
- Is validated to not exceed the maximum length of 64 characters

This function performs no Microsoft Graph I/O and has no side effects.

This function:
- Is intended for internal module use
- Is a pure helper (input → output, no state change)
- Throws terminating errors on invalid input or invalid generated output

.PARAMETER Intent
Specifies the group intent being named.
Supported values:
- LICENSE
- ENTRAROLE

.PARAMETER SkuPartNumber
License SKU part number used as the specifier in LICENSE group names.
Required when Intent is LICENSE.

.PARAMETER RoleName
Entra ID directory role display name used as the specifier in ENTRAROLE group names.
Required when Intent is ENTRAROLE.

.PARAMETER AssignmentType
Role assignment type used in ENTRAROLE group names.
Valid values:
- Active
- Eligible
Required when Intent is ENTRAROLE.

.OUTPUTS
System.String

.EXAMPLE
Get-MWEGroupDisplayName -Intent LICENSE -SkuPartNumber 'SPE_E5'

.EXAMPLE
Get-MWEGroupDisplayName -Intent ENTRAROLE -RoleName 'Global Administrator' -AssignmentType Eligible

.NOTES
- This is a deterministic naming helper.
- No Microsoft Graph calls are performed.
- Naming constraints are enforced centrally to ensure consistency across the module.

.REQUIRED GRAPH SCOPES
None (no Graph calls performed).

.LINK
https://learn.microsoft.com/graph/api/resources/group
#>

    [CmdletBinding()]
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
    $principalByIntent = @{
        LICENSE   = 'U'
        ENTRAROLE = 'U'
    }

    $principal = $principalByIntent[$Intent]
    if (-not $principal) { throw "No principal prefix mapping found for Intent '$Intent'." }

    $function = $Intent

    switch ($function) {
        'LICENSE' {
            if (-not $SkuPartNumber) {throw "SkuPartNumber is required when Intent is 'LICENSE'."}
            $groupName = "$principal-$function-$SkuPartNumber"
        }

        'ENTRAROLE' {
            if (-not $RoleName) {throw "RoleName is required when Intent is 'ENTRAROLE'."}
            if (-not $AssignmentType) {throw "AssignmentType is required when Intent is 'ENTRAROLE'."}
            $groupName = "$principal-$function-$RoleName-$($AssignmentType.ToUpperInvariant())"
        }
        #default is not needed because of parameter validation set.
    }
    # Sanitize and validate length
    $groupName=$groupName  -replace '[^a-zA-Z0-9_-]', ''
    if ($groupName.Length -gt 64) {
        throw "Generated group name '$groupName' exceeds maximum length of 64 characters."
    }
    return $groupName
}
