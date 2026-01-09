function Set-MWE<Thing> {
<#
.SYNOPSIS
Performs a single, well-defined state change as part of the MWE automation.

.DESCRIPTION
Implements a deterministic helper function that performs a single responsibility
operation (for example: assigning a license, setting a role assignment, updating
group properties).

This function:
- Is intended for internal module use
- Is safe to run multiple times (idempotent where applicable)
- Does not create high-level resources
- Does not perform orchestration logic
- Supports WhatIf / Confirm semantics

.PARAMETER <RequiredParameter>
Description of the required parameter.

.PARAMETER <OptionalParameter>
Description of the optional parameter.

.OUTPUTS
PSCustomObject describing the operation result, typically including:
- Target identifier
- Changed (Boolean)
- Action (string)

.EXAMPLE
Set-MWE<Thing> -<RequiredParameter> 'Value'

.EXAMPLE
Set-MWE<Thing> -<RequiredParameter> 'Value' -WhatIf

.NOTES
- Internal helper function
- Designed for reuse by higher-level orchestration functions
- Throws terminating errors on invalid input or Graph failures

.REQUIRED GRAPH SCOPES
Delegated or Application permissions:
- <Scope.One>
- <Scope.Two>

.LINK
https://learn.microsoft.com/graph/
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RequiredParameter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OptionalParameter
    )

    # --- Parameter guards / contract validation ---
    # throw on invalid or inconsistent input

    # --- Data lookup / normalization ---
    # Resolve IDs, fetch Graph state, prepare splats

    # --- Idempotency check ---
    # Detect whether the desired state already exists

    if ($alreadyInDesiredState) {
        Write-Verbose "<Thing> already in desired state."
        return [pscustomobject]@{
            Target  = $RequiredParameter
            Changed = $false
            Action  = 'NoChange'
        }
    }

    # --- State change ---
    try {
        if ($PSCmdlet.ShouldProcess("<Target>", "<Action description>")) {
            # Invoke Graph operation
        }

        Write-Verbose "<Thing> successfully updated."
        return [pscustomobject]@{
            Target  = $RequiredParameter
            Changed = $true
            Action  = 'Updated'
        }
    }
    catch {
        throw "Failed to update <Thing>: $($_.Exception.Message)"
    }
}