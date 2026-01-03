function Get-MWEExistingGroup {
    <#
    .SYNOPSIS
    Looks up an existing managed group for the declared intent.

    .DESCRIPTION
    Ensures lookup uses the same naming source of truth as creation by deriving
    group names via New-MWEGroupSplat (DEC-0004, DEC-0007).
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$ParameterSetName,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [string]$RoleName
    )

    switch ($ParameterSetName) {
        'LICENSE' {
            $displayName = (New-MWEGroupSplat -ParameterSetName 'LICENSE' -SkuPartNumber $SkuPartNumber).DisplayName
            return Get-MgGroup -Filter "displayName eq '$displayName'" -Top 1
        }

        'ENTRAROLE' {
            $eligibleName = (New-MWEGroupSplat -ParameterSetName 'ENTRAROLE' -RoleName $RoleName -AssignmentType 'Eligible').DisplayName
            $activeName   = (New-MWEGroupSplat -ParameterSetName 'ENTRAROLE' -RoleName $RoleName -AssignmentType 'Active').DisplayName

            $existingGroup = Get-MgGroup -Filter "displayName eq '$eligibleName'" -Top 1
            if ($null -eq $existingGroup) {
                $existingGroup = Get-MgGroup -Filter "displayName eq '$activeName'" -Top 1
            }
            return $existingGroup
        }
    }
}
