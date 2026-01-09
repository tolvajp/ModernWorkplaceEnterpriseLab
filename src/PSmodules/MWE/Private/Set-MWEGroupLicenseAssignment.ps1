function Set-MWEGroupLicenseAssignment {
    <#
.SYNOPSIS
Assigns a Microsoft 365 license to an Entra ID group using group-based licensing.

.DESCRIPTION
Assigns a Microsoft 365 license to an Entra ID security group using Microsoft Graph
group-based licensing.

The function supports two input modes:
- By SkuId
- By SkuPartNumber (resolved to SkuId at runtime)

Depending on the provided parameters, this function:
- Resolves the license SKU when specified by SkuPartNumber
- Assigns the license to the target group using Microsoft Graph
- Performs a state-changing operation in Entra ID
- Emits an informational log entry when the assignment succeeds
- Supports WhatIf / Confirm semantics for safe execution

Authentication and required Microsoft Graph permissions are explicit preconditions.

.PARAMETER GroupId
The object ID of the Entra ID group to which the license will be assigned.

.PARAMETER SkuId
The GUID of the license SKU to assign.

This parameter is mandatory when using the 'BySkuId' parameter set.

.PARAMETER SkuPartNumber
The SKU part number of the license to assign
(for example: ENTERPRISEPREMIUM, EMSPREMIUM).

This parameter is mandatory when using the 'BySkuPartNumber' parameter set.
The SKU is resolved to its corresponding SkuId at runtime.

.OUTPUTS
None.

This function does not return output objects.
Successful execution is indicated via informational log messages.

.EXAMPLE
Set-MWEGroupLicenseAssignment `
    -GroupId '11111111-1111-1111-1111-111111111111' `
    -SkuId '22222222-2222-2222-2222-222222222222'

Assigns the specified license SKU to the target group using its SkuId.

.EXAMPLE
Set-MWEGroupLicenseAssignment `
    -GroupId '33333333-3333-3333-3333-333333333333' `
    -SkuPartNumber ENTERPRISEPREMIUM

Resolves the ENTERPRISEPREMIUM SKU and assigns the corresponding license
to the target group.

.EXAMPLE
Set-MWEGroupLicenseAssignment `
    -GroupId '44444444-4444-4444-4444-444444444444' `
    -SkuPartNumber EMSPREMIUM `
    -WhatIf

Shows what would happen if the EMSPREMIUM license were assigned to the group,
without making any changes.

.NOTES
- This function performs a state-changing operation in Entra ID.
- Authentication and Microsoft Graph permission consent are required preconditions.
- Microsoft Graph errors are not wrapped or altered.
- Intended for internal use within the MWE automation framework.

.REQUIRED GRAPH SCOPES
Delegated or Application permissions:
- Group.ReadWrite.All
- Directory.ReadWrite.All

.LINK
https://learn.microsoft.com/graph/api/group-assign-license

.LINK
https://learn.microsoft.com/entra/identity/users/licensing-group-based
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory, ParameterSetName = 'BySkuId')]
        [ValidateNotNullOrEmpty()]
        [guid]$SkuId,

        [Parameter(Mandatory, ParameterSetName = 'BySkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber
    )
    $ErrorActionPreference = 'Stop'
    if (-not $PSBoundParameters.ContainsKey('SkuId')) {
        $subscribedSkuSplat = @{
            ErrorAction = 'Stop'
        }
        $sku = Invoke-MWECommand -Command 'Get-MgSubscribedSku' -Splat $subscribedSkuSplat | Where-Object SkuPartNumber -eq $SkuPartNumber | Select-Object -First 1
        if (-not $sku) { throw "No such subscribed SKU found (SkuPartNumber): '$SkuPartNumber'." }
        $SkuId = $sku.SkuId
    }

    if ($PSCmdlet.ShouldProcess($GroupId, "Assign license $SkuID to group")) {
        $licenseSplat = @{
            GroupId        = $GroupId
            AddLicenses    = @(@{ SkuId = $SkuId })
            RemoveLicenses = @()
        }

        try {
            Invoke-MWECommand -Command 'Set-MgGroupLicense' -Splat $licenseSplat
            Write-Information -MessageData "Assigned license $SkuID to group $GroupId"
        }
        catch {
            throw
        }
    }
}
