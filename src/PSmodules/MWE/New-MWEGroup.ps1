function New-MWEGroup {
    <#
.SYNOPSIS
Creates a Microsoft Entra ID security group according to enforced MWE decisions.

.DESCRIPTION
Creates a Microsoft Entra ID security group following the
Modern Workplace Enterprise (MWE) decision model.

The function enforces architectural decisions around:
- group purpose and intent
- deterministic naming
- idempotent creation
- optional group-based license assignment

The active parameter set represents the **group intent category**
(e.g. LICENSE today; future categories may include ROLE, DEPARTMENT, etc.).

For the LICENSE parameter set, the function is aligned with DEC-0005
(License Distribution Model).

---

GROUP NAMING MODEL

The group display name is constructed deterministically as:

    <Principal>-<Function>-<Specifier>

Where:
- Principal indicates the identity scope:
  - U = User
  - D = Device
  - X = Mixed
- Function represents the enforced group category token (e.g. LIC)
- Specifier is provided by the caller (e.g. license identifier)

Example (license group):

    U-LICENSE-SPE_E5

The resulting displayName is normalized by removing all characters except:
- A–Z
- a–z
- 0–9
- underscore (_)
- hyphen (-)

A maximum length of 64 characters is enforced.

If a group with the same displayName already exists, the function throws.
This indicates an attempt to create a second group for the same declared intent.

---

BEHAVIOR

- The group is created via Microsoft Graph.
- Group creation is idempotent by intent (duplicate intent results in throw).
- When -Mock is specified:
  - the group is created
  - no license is assigned
- When -Mock is not specified:
  - the group is created
  - the specified license is assigned to the group (group-based licensing)

Supports -WhatIf and -Confirm.

---

.PARAMETER SkuPartNumber
Specifies the license identifier used as the specifier in the group name.
In non-mock mode, the value must correspond to a license SKU present in the tenant.

.PARAMETER Mock
When specified, skips license assignment.
Used to model license groups without requiring the license to exist in the tenant.
Only there to be able to create groups for licenses not purchased in the lab tenant.

---

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5'

Creates a license assignment group:
    U-LIC-SPE_E5
and assigns the license to the group.

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock

Creates the group without assigning a license.

.EXAMPLE
PS> New-MWEGroup -SkuPartNumber 'SPE_E5' -WhatIf

Shows what would happen without creating the group or assigning a license.

---

.OUTPUTS
Microsoft.Graph.PowerShell.Models.IMicrosoftGraphGroup

Returns the created group object when the group is created,
or $null when -WhatIf is used.

---

.NOTES
This function is part of the MWE module and is intended for lab automation.

Architectural disclaimer:
This function enforces group-related decisions (naming, structure, and intent).
Any modification to this function may require corresponding updates to
decision records and documentation.

In real enterprise environments, such changes should be subject to
formal change management and approval processes.

Prerequisites (delegated permissions):
- Group.ReadWrite.All
- LicenseAssignment.ReadWrite.All

Admin consent is required.
#>


    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'LICENSE')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'LICENSE')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber,

        [Parameter(ParameterSetName = 'LICENSE')]
        [switch]$Mock
    )

    #Parameter validation is handled here since sometimes it needs several parameters.
    switch ($PSCmdlet.ParameterSetName) {

        'LICENSE' {
            if ((-not $Mock) -and ($SkuPartNumber -notin  (Get-MgSubscribedSku).SkuPartNumber)) {
            throw "No such License bought for the company: $SkuPartNumber"
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
    }

    #Group creation
    $existingGroup = Get-MgGroup -Filter "displayName eq '$($groupSplat.DisplayName)'" -Top 1
    if ($existingGroup) {
        throw "Group '$($groupSplat.DisplayName)' already exists with Id: $($existingGroup.Id). Use that one."
    }
    else {
        if ($PSCmdlet.ShouldProcess($groupSplat.DisplayName, 'Create Entra ID group')) {
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

    return $newGroup
}
