function New-MWEGroup {
    <#
    .SYNOPSIS
    Creates a role-scoped Microsoft Entra ID group using enforced MWE decisions.

    .DESCRIPTION
    Creates a Microsoft Entra ID group according to the Modern Workplace Enterprise (MWE)
    decision model.

    The active parameter set name represents the intended group category
    (e.g. DUMMY today; future sets such as LICENSE, ROLE, DEPARTMENT, etc.).
    Based on this parameter set, the function enforces standardized decisions for
    group naming and configuration in order to prevent configuration drift.

    The group display name is constructed deterministically as:

        <Principal>-<Function>-<Specifier>-<Specifier>

    Where:
    - Principal represents group type (U for User, D for Device, X for Mixed.) 
    - Function equals the active parameter set name that represents group category
    - Name is provided by the caller, represents specifier.

    The resulting displayName is normalized by removing all characters except:
        A–Z, a–z, 0–9, underscore (_) and hyphen (-)

    A maximum length of 64 characters is enforced.
    If a group with the same displayName already exists, the function throws,
    as this indicates an attempt to create a second group for the same purpose.

    Otherwise, the group is created via Microsoft Graph.

    Supports -WhatIf and -Confirm.

    .PARAMETER Name
    Name represents Specifier token appended to the standardized group name.
    
    .EXAMPLE
    PS> New-MWEGroup -Name 'Test01'

    Creates a security group using the active parameter set, for example:
        U-DUMMY-Test01

    .EXAMPLE
    PS> New-MWEGroup -Name 'Test01' -WhatIf

    Shows what would happen without creating the group.

    .OUTPUTS
    Microsoft.Graph.PowerShell.Models.IMicrosoftGraphGroup

    Returns the created group object when the group is created,
    or $null when -WhatIf is used.

    .NOTES
    This function is part of the MWE module and is intended for lab automation.

    Architectural disclaimer:
    This function enforces group-related decisions (naming, structure, and intent).
    Any modification to this function is likely to require corresponding updates to
    documentation and decision records. In real environments, such changes should
    go through formal change management.

    Prerequisites:
    the script needs the following scopes:
    -"Group.ReadWrite.All"

    Admin consent is mandatory.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'DUMMY')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'DUMMY')]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $newGroup = $null
    $groupSplat = switch ($PSCmdlet.ParameterSetName) {

        'DUMMY' {
            $prefix = 'U'
            $principal = $PSCmdlet.ParameterSetName
            $normalizedDisplayName = "$prefix-$principal-$Name" -replace '[^a-zA-Z0-9_-]', ''

            if ($normalizedDisplayName.Length -gt 64) {
                throw "Normalized group name '$normalizedDisplayName' is longer than 64 characters. Shorten the input."
            }

            @{
                DisplayName     = $normalizedDisplayName
                Description     = "$Name $principal group"
                MailEnabled     = $false
                SecurityEnabled = $true
                MailNickname    = $normalizedDisplayName
            }
        }
    }

    $existingGroup = Get-MgGroup -Filter "displayName eq '$($groupSplat.DisplayName)'"-Top 1
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

    return $newGroup
}
