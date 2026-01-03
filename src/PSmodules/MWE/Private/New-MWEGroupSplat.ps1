function New-MWEGroupSplat {
    <#
    .SYNOPSIS
    Builds the splat hashtable for New-MgGroup based on group intent.

    .DESCRIPTION
    Centralizes deterministic naming and baseline metadata for managed groups.
    The Principal prefix is derived from the group intent (ParameterSetName) so
    future intents (e.g. device groups) can introduce new principals without
    changing the public function (DEC-0004, DEC-0007).
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$ParameterSetName,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [string]$RoleName,

        [Parameter()]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType
    )

    $functionToken = $ParameterSetName

    # Principal prefix mapping is intent-driven (ParameterSetName). Today both intents are user-scoped,
    # but this mapping is intentionally extensible for future device/mixed group intents.
    $prefixByIntent = @{
        LICENSE   = 'U'
        ENTRAROLE = 'U'
    }

    $prefix = $prefixByIntent[$ParameterSetName]
    if (-not $prefix) { throw "No principal prefix mapping found for ParameterSetName '$ParameterSetName'." }

    $displayNameRaw = switch ($ParameterSetName) {
        'LICENSE' {
            "$prefix-$functionToken-$SkuPartNumber"
        }
        'ENTRAROLE' {
            "$prefix-$functionToken-$RoleName-$($AssignmentType.ToUpper())"
        }
    }

    $normalizedDisplayName = ConvertTo-NWEStandardizedName -InputName $displayNameRaw -MaxLength 64

    switch ($ParameterSetName) {
        'LICENSE' {
            return @{
                DisplayName     = $normalizedDisplayName
                Description     = "License assignment group for $SkuPartNumber"
                MailEnabled     = $false
                SecurityEnabled = $true
                MailNickname    = $normalizedDisplayName
            }
        }
        'ENTRAROLE' {
            return @{
                DisplayName        = $normalizedDisplayName
                Description        = "Entra role assignment group for $RoleName"
                MailEnabled        = $false
                SecurityEnabled    = $true
                MailNickname       = $normalizedDisplayName
                IsAssignableToRole = $true
            }
        }
    }
}
