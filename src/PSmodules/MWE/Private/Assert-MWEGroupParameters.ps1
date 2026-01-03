function Assert-MWEGroupParameters {
    <#
    .SYNOPSIS
    Validates parameters and tenant preconditions for New-MWEGroup.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('LICENSE','ENTRAROLE')]
        [string]$ParameterSetName,

        [Parameter()]
        [string]$SkuPartNumber,

        [Parameter()]
        [switch]$Mock,

        [Parameter()]
        [string]$RoleName,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [int]$MaximumActivationHours
    )

    switch ($ParameterSetName) {
        'LICENSE' {
            if ((-not $Mock) -and ($SkuPartNumber -notin (Get-MgSubscribedSku).SkuPartNumber)) {
                throw "No such License bought for the company: $SkuPartNumber"
            }

            return [pscustomobject]@{}
        }

        'ENTRAROLE' {
            $templateRoles  = Get-MgDirectoryRoleTemplate -All
            $activatedRoles = Get-MgDirectoryRole -All

            if ($RoleName -notin $templateRoles.DisplayName) {
                throw "No such Entra directory role template: $RoleName"
            }

            if ((-not $Force) -and ($RoleName -notin $activatedRoles.DisplayName)) {
                throw "No such Active Entra directory role: $RoleName Consider using the -Force parameter to activate it."
            }

            if ($MaximumActivationHours -lt 1 -or $MaximumActivationHours -gt 9) {
                throw "MaximumActivationHours must be between 1 and 9."
            }

            return [pscustomobject]@{
                TemplateRoles  = $templateRoles
                ActivatedRoles = $activatedRoles
            }
        }
    }
}
